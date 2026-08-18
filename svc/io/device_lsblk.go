package io

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"path/filepath"
	"strconv"
	"strings"
)

// lsblkNode mirrors one entry of `lsblk -J`.
type lsblkNode struct {
	Name       string      `json:"name"`
	Type       string      `json:"type"`
	Tran       string      `json:"tran"`
	Size       json.Number `json:"size"`
	Model      string      `json:"model"`
	Rota       bool        `json:"rota"`
	MountPoint string      `json:"mountpoint"`
	Children   []lsblkNode `json:"children"`
}

type lsblkOutput struct {
	BlockDevices []lsblkNode `json:"blockdevices"`
}

// linuxDevices combines lsblk (topology, transport, mounts) with sysfs
// (queue and USB descriptors). lsblk owns the tree; sysfs owns the facts
// lsblk cannot see.
func (s *Service) linuxDevices(ctx context.Context, errOut io.Writer) ([]Device, error) {
	raw, err := s.runOutput(ctx, nil, errOut, "lsblk", "-J", "-b", "-o", "NAME,TYPE,TRAN,SIZE,MODEL,ROTA,MOUNTPOINT")
	if err != nil {
		return nil, err
	}
	nodes, err := parseLsblk(raw)
	if err != nil {
		return nil, err
	}
	devices := make([]Device, 0, len(nodes))
	for _, node := range nodes {
		if node.Type != "disk" {
			continue
		}
		device := Device{
			Name:      node.Name,
			Transport: node.Tran,
			Model:     strings.TrimSpace(node.Model),
			Mounts:    mountsOf(node),
		}
		if size, err := node.Size.Int64(); err == nil {
			device.SizeBytes = size
		}
		if node.Rota {
			device.Rotational = "1"
		} else {
			device.Rotational = "0"
		}
		s.fillSysfs(&device)
		devices = append(devices, device)
	}
	return devices, nil
}

func parseLsblk(raw []byte) ([]lsblkNode, error) {
	var output lsblkOutput
	if err := json.Unmarshal(raw, &output); err != nil {
		return nil, fmt.Errorf("parse lsblk JSON: %w", err)
	}
	return output.BlockDevices, nil
}

// mountsOf flattens every mounted descendant into "name=mountpoint".
func mountsOf(node lsblkNode) []string {
	var mounts []string
	var walk func(lsblkNode)
	walk = func(current lsblkNode) {
		for _, child := range current.Children {
			if child.MountPoint != "" {
				mounts = append(mounts, child.Name+"="+child.MountPoint)
			}
			walk(child)
		}
	}
	walk(node)
	return mounts
}

// fillSysfs reads /sys/block/<dev>/queue and, for USB devices, walks up the
// device chain to the interface's parent (the node that carries idVendor).
func (s *Service) fillSysfs(device *Device) {
	queue := filepath.Join("/sys/block", device.Name, "queue")
	device.QueueDepth = s.sysfsValue(filepath.Join(queue, "nr_requests"))
	device.WriteCache = s.sysfsValue(filepath.Join(queue, "write_cache"))

	devicePath, err := s.evalSymlinks(filepath.Join("/sys/block", device.Name, "device"))
	if err != nil {
		return
	}
	device.Driver = s.hostDriver(devicePath)
	if device.Transport != "usb" {
		return
	}
	for path := devicePath; path != "/" && path != "."; path = filepath.Dir(path) {
		vendor := s.sysfsValue(filepath.Join(path, "idVendor"))
		if vendor == "" {
			continue
		}
		device.ID = vendor + ":" + s.sysfsValue(filepath.Join(path, "idProduct"))
		if speed := s.sysfsValue(filepath.Join(path, "speed")); speed != "" {
			device.Link = speed + "Mbps"
		}
		if product := s.sysfsValue(filepath.Join(path, "product")); product != "" {
			device.Model = product
		}
		return
	}
}

// hostDriver resolves the SCSI host's driver: "uas" queues commands,
// "usb-storage" (bulk-only transport) does not.
func (s *Service) hostDriver(devicePath string) string {
	for path := devicePath; path != "/" && path != "."; path = filepath.Dir(path) {
		base := filepath.Base(path)
		if !strings.HasPrefix(base, "host") {
			continue
		}
		if _, err := strconv.Atoi(strings.TrimPrefix(base, "host")); err != nil {
			continue
		}
		driver, err := s.readLink(filepath.Join(filepath.Dir(path), "driver"))
		if err != nil {
			return ""
		}
		return filepath.Base(driver)
	}
	return ""
}

func (s *Service) sysfsValue(path string) string {
	raw, err := s.readFile(path)
	if err != nil {
		return ""
	}
	return strings.TrimSpace(string(raw))
}
