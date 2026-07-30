// Package system provides cross-platform system information probes.
package system

import (
	"context"
	"io"
)

type probe func(*Service, context.Context, io.Writer, io.Writer) error

// Information describes one system information command.
type Information struct {
	Name        string
	Description string
	show        probe
}

var informationCatalog = []Information{
	{Name: "os", Description: "作業系統版本、架構與日期", show: (*Service).showOS},
	{Name: "cpu", Description: "CPU 型號與核心數", show: (*Service).showCPU},
	{Name: "memory", Description: "記憶體容量", show: (*Service).showMemory},
	{Name: "gpu", Description: "GPU 型號", show: (*Service).showGPU},
	{Name: "disk", Description: "根分割區容量與使用率", show: (*Service).showDisk},
	{Name: "usb", Description: "USB 裝置", show: (*Service).showUSB},
	{Name: "display", Description: "顯示器解析度", show: (*Service).showDisplay},
	{Name: "network", Description: "本機網路介面與 IP 位址", show: (*Service).showNetwork},
	{Name: "input", Description: "輸入裝置", show: (*Service).showInput},
	{Name: "audio", Description: "音訊輸出裝置", show: (*Service).showAudio},
}

// Catalog returns a defensive copy of the system information catalog.
func Catalog() []Information {
	return append([]Information(nil), informationCatalog...)
}

func findInformation(name string) (Information, bool) {
	for _, information := range informationCatalog {
		if information.Name == name {
			return information, true
		}
	}
	return Information{}, false
}
