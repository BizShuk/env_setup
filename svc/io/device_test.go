package io

import (
	"bytes"
	"context"
	"errors"
	"io"
	"os"
	"strings"
	"testing"
)

type fakeRunner struct {
	outputs map[string]string
}

func (r fakeRunner) Run(_ context.Context, in io.Reader, out, _ io.Writer, name string, args ...string) error {
	key := strings.Join(append([]string{name}, args...), " ")
	if name == "plutil" {
		// The probe pipes plist through plutil; the fake echoes stdin so
		// tests can hand JSON straight to the diskutil fakes.
		_, err := io.Copy(out, in)
		return err
	}
	output, ok := r.outputs[key]
	if !ok {
		return errors.New("unexpected command " + key)
	}
	_, err := io.WriteString(out, output)
	return err
}

const LSBLK_JSON = `{"blockdevices":[
 {"name":"sda","type":"disk","tran":"usb","size":250059350016,"model":" SanDisk 3.2Gen1","rota":true,"mountpoint":null,
  "children":[{"name":"vg--256-var","type":"lvm","tran":null,"size":1,"model":null,"rota":true,"mountpoint":"/var"},
              {"name":"vg--256-home","type":"lvm","tran":null,"size":1,"model":null,"rota":true,"mountpoint":"/home"}]},
 {"name":"mmcblk0","type":"disk","tran":"mmc","size":31268536320,"model":null,"rota":false,"mountpoint":null,
  "children":[{"name":"mmcblk0p1","type":"part","tran":null,"size":1,"model":null,"rota":false,"mountpoint":"/boot/efi"}]},
 {"name":"loop0","type":"loop","tran":null,"size":1,"model":null,"rota":false,"mountpoint":"/snap"}
]}`

func TestLinuxDevicesCombinesLsblkAndSysfs(t *testing.T) {
	sysfs := map[string]string{
		"/sys/block/sda/queue/nr_requests":           "2\n",
		"/sys/block/sda/queue/write_cache":           "write through\n",
		"/sys/devices/pci0000:00/usb2/2-2/idVendor":  "0781\n",
		"/sys/devices/pci0000:00/usb2/2-2/idProduct": "5583\n",
		"/sys/devices/pci0000:00/usb2/2-2/speed":     "5000\n",
		"/sys/devices/pci0000:00/usb2/2-2/product":   " SanDisk 3.2Gen1\n",
		"/sys/block/mmcblk0/queue/nr_requests":       "64\n",
		"/sys/block/mmcblk0/queue/write_cache":       "write back\n",
	}
	resolved := map[string]string{
		"/sys/block/sda/device":     "/sys/devices/pci0000:00/usb2/2-2/2-2:1.0/host0/target0:0:0/0:0:0:0",
		"/sys/block/mmcblk0/device": "/sys/devices/pci0000:00/mmc0/mmc0:0001",
	}
	links := map[string]string{
		"/sys/devices/pci0000:00/usb2/2-2/2-2:1.0/driver": "../../../../../bus/usb/drivers/usb-storage",
	}
	service := New(Options{
		GOOS:   "linux",
		Runner: fakeRunner{outputs: map[string]string{"lsblk -J -b -o NAME,TYPE,TRAN,SIZE,MODEL,ROTA,MOUNTPOINT": LSBLK_JSON}},
		ReadFile: func(path string) ([]byte, error) {
			value, ok := sysfs[path]
			if !ok {
				return nil, os.ErrNotExist
			}
			return []byte(value), nil
		},
		ReadLink: func(path string) (string, error) {
			value, ok := links[path]
			if !ok {
				return "", os.ErrNotExist
			}
			return value, nil
		},
		EvalSymlinks: func(path string) (string, error) {
			value, ok := resolved[path]
			if !ok {
				return "", os.ErrNotExist
			}
			return value, nil
		},
	})

	devices, err := service.Devices(context.Background(), io.Discard)
	if err != nil {
		t.Fatalf("Devices: %v", err)
	}
	if len(devices) != 2 {
		t.Fatalf("devices = %d, want 2 (loop excluded)", len(devices))
	}
	sda := devices[0]
	want := Device{
		Name: "sda", Transport: "usb", ID: "0781:5583", Model: "SanDisk 3.2Gen1", SizeBytes: 250059350016,
		Link: "5000Mbps", Driver: "usb-storage", QueueDepth: "2", WriteCache: "write through", Rotational: "1",
		Mounts: []string{"vg--256-var=/var", "vg--256-home=/home"},
	}
	if sda.Name != want.Name || sda.Transport != want.Transport || sda.ID != want.ID || sda.Model != want.Model ||
		sda.SizeBytes != want.SizeBytes || sda.Link != want.Link || sda.Driver != want.Driver ||
		sda.QueueDepth != want.QueueDepth || sda.WriteCache != want.WriteCache || sda.Rotational != want.Rotational ||
		strings.Join(sda.Mounts, ",") != strings.Join(want.Mounts, ",") {
		t.Errorf("sda = %+v, want %+v", sda, want)
	}
	mmc := devices[1]
	if mmc.Transport != "mmc" || mmc.ID != "" || mmc.QueueDepth != "64" || mmc.Rotational != "0" ||
		strings.Join(mmc.Mounts, ",") != "mmcblk0p1=/boot/efi" {
		t.Errorf("mmcblk0 = %+v", mmc)
	}
}

const DISKUTIL_LIST_JSON = `{"WholeDisks":["disk0","disk3","disk6"],"AllDisksAndPartitions":[
 {"DeviceIdentifier":"disk0","Content":"GUID_partition_scheme","Size":1,"Partitions":[{"DeviceIdentifier":"disk0s2"}]},
 {"DeviceIdentifier":"disk3","Content":"Apple_APFS_Container","Size":1,"APFSPhysicalStores":[{"DeviceIdentifier":"disk0s2"}],
  "APFSVolumes":[{"DeviceIdentifier":"disk3s1s1","MountPoint":"/"},{"DeviceIdentifier":"disk3s5","MountPoint":"/System/Volumes/Data"}]},
 {"DeviceIdentifier":"disk6","Content":"GUID_partition_scheme","Size":1,"Partitions":[{"DeviceIdentifier":"disk6s1"},{"DeviceIdentifier":"disk6s2","MountPoint":"/Volumes/action"}]}
]}`

func TestDarwinDevicesAttributesAPFSVolumesToPhysicalDisk(t *testing.T) {
	service := New(Options{
		GOOS: "darwin",
		Runner: fakeRunner{outputs: map[string]string{
			"diskutil list -plist":       DISKUTIL_LIST_JSON,
			"diskutil info -plist disk0": `{"MediaName":"APPLE SSD","BusProtocol":"Apple Fabric","SolidState":true,"TotalSize":1000,"VirtualOrPhysical":"Unknown"}`,
			"diskutil info -plist disk3": `{"MediaName":"","BusProtocol":"","SolidState":true,"TotalSize":900,"VirtualOrPhysical":"Virtual"}`,
			"diskutil info -plist disk6": `{"MediaName":"SE880","BusProtocol":"USB","TotalSize":2000,"VirtualOrPhysical":"Physical"}`,
		}},
	})
	devices, err := service.Devices(context.Background(), io.Discard)
	if err != nil {
		t.Fatalf("Devices: %v", err)
	}
	if len(devices) != 2 {
		t.Fatalf("devices = %+v, want disk0 and disk6 only", devices)
	}
	if got := strings.Join(devices[0].Mounts, ","); got != "disk3s1s1=/,disk3s5=/System/Volumes/Data" {
		t.Errorf("disk0 mounts = %q", got)
	}
	if devices[1].Transport != "usb" || devices[1].Model != "SE880" || strings.Join(devices[1].Mounts, ",") != "disk6s2=/Volumes/action" {
		t.Errorf("disk6 = %+v", devices[1])
	}
	if devices[0].QueueDepth != "" || devices[0].WriteCache != "" || devices[0].Rotational != "0" {
		t.Errorf("darwin must leave QD/WCACHE empty and mark internal SSD non-rotational, got %+v", devices[0])
	}
	if devices[1].Rotational != "" {
		t.Errorf("unknown SolidState must render as -, got %q", devices[1].Rotational)
	}
}

func TestRenderDevicesUsesDashForUnknown(t *testing.T) {
	var out bytes.Buffer
	if err := renderDevices(&out, []Device{{Name: "disk6", Transport: "usb", SizeBytes: 1000204886016}}); err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(out.String(), "disk6  usb   -   -      931.5G  -     -       -   -       -     -") {
		t.Errorf("render = %q", out.String())
	}
}
