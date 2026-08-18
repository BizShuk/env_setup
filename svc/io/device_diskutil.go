package io

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"strings"
)

// diskutilList mirrors the parts of `diskutil list -plist` the probe needs.
type diskutilList struct {
	AllDisksAndPartitions []diskutilDisk `json:"AllDisksAndPartitions"`
	WholeDisks            []string       `json:"WholeDisks"`
}

type diskutilDisk struct {
	DeviceIdentifier   string              `json:"DeviceIdentifier"`
	Content            string              `json:"Content"`
	Size               int64               `json:"Size"`
	Partitions         []diskutilVolume    `json:"Partitions"`
	APFSVolumes        []diskutilVolume    `json:"APFSVolumes"`
	APFSPhysicalStores []diskutilReference `json:"APFSPhysicalStores"`
}

type diskutilVolume struct {
	DeviceIdentifier string `json:"DeviceIdentifier"`
	MountPoint       string `json:"MountPoint"`
}

type diskutilReference struct {
	DeviceIdentifier string `json:"DeviceIdentifier"`
}

// diskutilInfo mirrors the parts of `diskutil info -plist <disk>` the probe needs.
type diskutilInfo struct {
	MediaName         string `json:"MediaName"`
	BusProtocol       string `json:"BusProtocol"`
	SolidState        *bool  `json:"SolidState"`
	TotalSize         int64  `json:"TotalSize"`
	VirtualOrPhysical string `json:"VirtualOrPhysical"`
}

// darwinDevices lists whole disks that are not APFS synthesized containers.
// Apple's internal SSD reports VirtualOrPhysical as "Unknown", so only
// "Virtual" is excluded. macOS exposes no queue depth or write-cache policy to
// userland, so those columns stay "-"; APFS volumes are attributed to the
// physical disk that backs their container.
func (s *Service) darwinDevices(ctx context.Context, errOut io.Writer) ([]Device, error) {
	raw, err := s.plistJSON(ctx, errOut, "diskutil", "list", "-plist")
	if err != nil {
		return nil, err
	}
	var list diskutilList
	if err := json.Unmarshal(raw, &list); err != nil {
		return nil, fmt.Errorf("parse diskutil list: %w", err)
	}
	mounts := darwinMountsByDisk(list)

	var devices []Device
	for _, name := range list.WholeDisks {
		raw, err := s.plistJSON(ctx, errOut, "diskutil", "info", "-plist", name)
		if err != nil {
			return nil, err
		}
		var info diskutilInfo
		if err := json.Unmarshal(raw, &info); err != nil {
			return nil, fmt.Errorf("parse diskutil info %s: %w", name, err)
		}
		if info.VirtualOrPhysical == "Virtual" {
			continue
		}
		device := Device{
			Name:      name,
			Transport: strings.ToLower(info.BusProtocol),
			Model:     info.MediaName,
			SizeBytes: info.TotalSize,
			Mounts:    mounts[name],
		}
		// diskutil omits SolidState when it cannot tell (typical for USB
		// bridges); "-" is more honest than guessing spinning.
		if info.SolidState != nil {
			if *info.SolidState {
				device.Rotational = "0"
			} else {
				device.Rotational = "1"
			}
		}
		devices = append(devices, device)
	}
	return devices, nil
}

// darwinMountsByDisk maps each physical whole disk to "volume=mountpoint"
// entries: its own partitions plus the APFS volumes of any container whose
// physical store lives on one of those partitions.
func darwinMountsByDisk(list diskutilList) map[string][]string {
	partitionOwner := make(map[string]string)
	for _, disk := range list.AllDisksAndPartitions {
		for _, partition := range disk.Partitions {
			partitionOwner[partition.DeviceIdentifier] = disk.DeviceIdentifier
		}
	}
	mounts := make(map[string][]string)
	for _, disk := range list.AllDisksAndPartitions {
		for _, partition := range disk.Partitions {
			if partition.MountPoint != "" {
				mounts[disk.DeviceIdentifier] = append(mounts[disk.DeviceIdentifier], partition.DeviceIdentifier+"="+partition.MountPoint)
			}
		}
		if len(disk.APFSPhysicalStores) == 0 {
			continue
		}
		owner := partitionOwner[disk.APFSPhysicalStores[0].DeviceIdentifier]
		if owner == "" {
			owner = disk.DeviceIdentifier
		}
		for _, volume := range disk.APFSVolumes {
			if volume.MountPoint != "" {
				mounts[owner] = append(mounts[owner], volume.DeviceIdentifier+"="+volume.MountPoint)
			}
		}
	}
	return mounts
}

// plistJSON runs a plist-emitting command and normalises its output through
// plutil, because Go has no plist decoder in the standard library.
func (s *Service) plistJSON(ctx context.Context, errOut io.Writer, name string, args ...string) ([]byte, error) {
	plist, err := s.runOutput(ctx, nil, errOut, name, args...)
	if err != nil {
		return nil, err
	}
	return s.runOutput(ctx, bytes.NewReader(plist), errOut, "plutil", "-convert", "json", "-o", "-", "-")
}
