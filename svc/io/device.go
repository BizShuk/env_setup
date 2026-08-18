package io

import (
	"context"
	"fmt"
	"io"
	"strings"
	"text/tabwriter"
)

// Device is one whole block device and the facts that decide whether it can
// carry fsync-heavy workloads.
type Device struct {
	// Name is the kernel/OS device name (sda, nvme0n1, disk4).
	Name string
	// Transport is the bus the device hangs off (usb, nvme, sata, mmc, ...).
	Transport string
	// ID is idVendor:idProduct for USB devices, "-" otherwise.
	ID string
	// Model is the product string.
	Model string
	// SizeBytes is the raw capacity.
	SizeBytes int64
	// Link is the negotiated link speed when the bus exposes one.
	Link string
	// Driver is the host driver (uas vs usb-storage matters: BOT is QD 1-2).
	Driver string
	// QueueDepth is the request-queue depth ("-" when the OS does not expose it).
	QueueDepth string
	// WriteCache is "write back" / "write through" or "-".
	WriteCache string
	// Rotational reports whether the OS treats the device as spinning.
	Rotational string
	// Mounts lists filesystem or volume mounts carried by the device.
	Mounts []string
}

// Devices lists whole block devices for the current platform.
func (s *Service) Devices(ctx context.Context, errOut io.Writer) ([]Device, error) {
	switch s.goos {
	case "linux":
		return s.linuxDevices(ctx, errOut)
	case "darwin":
		return s.darwinDevices(ctx, errOut)
	default:
		return nil, fmt.Errorf("unsupported platform %q", s.goos)
	}
}

func renderDevices(out io.Writer, devices []Device) error {
	writer := tabwriter.NewWriter(out, 0, 0, 2, ' ', 0)
	fmt.Fprintln(writer, "DEV\tTRAN\tID\tMODEL\tSIZE\tLINK\tDRIVER\tQD\tWCACHE\tROTA\tMOUNTS")
	if len(devices) == 0 {
		fmt.Fprintln(writer, "(no block devices)")
		return writer.Flush()
	}
	for _, device := range devices {
		fmt.Fprintf(
			writer,
			"%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n",
			device.Name,
			orDash(device.Transport),
			orDash(device.ID),
			orDash(device.Model),
			humanBytes(device.SizeBytes),
			orDash(device.Link),
			orDash(device.Driver),
			orDash(device.QueueDepth),
			orDash(device.WriteCache),
			orDash(device.Rotational),
			orDash(strings.Join(device.Mounts, ",")),
		)
	}
	return writer.Flush()
}

func orDash(value string) string {
	value = strings.TrimSpace(value)
	if value == "" {
		return "-"
	}
	return value
}

func humanBytes(size int64) string {
	const UNIT = 1024
	if size < UNIT {
		return fmt.Sprintf("%dB", size)
	}
	value := float64(size)
	suffixes := []string{"K", "M", "G", "T", "P"}
	index := -1
	for value >= UNIT && index < len(suffixes)-1 {
		value /= UNIT
		index++
	}
	return fmt.Sprintf("%.1f%s", value, suffixes[index])
}
