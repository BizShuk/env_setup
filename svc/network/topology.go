package network

import (
	"fmt"
	"net/netip"
	"strings"
)

type topologyLayer struct {
	hop    netip.Addr
	prefix netip.Prefix
	hosts  []scannedHost
}

func renderTopology(localAddress netip.Addr, hostname string, layers []topologyLayer) string {
	var output strings.Builder
	fmt.Fprintf(
		&output,
		"本地主機 (Local Host): %s (%s)\n",
		localAddress,
		strings.TrimSuffix(hostname, ".local"),
	)

	indent := ""
	for _, layer := range layers {
		fmt.Fprintf(
			&output,
			"%s└── 網路子網拓撲 (Network Subnet Topology): %s\n",
			indent,
			layer.prefix,
		)
		indent += "    "
		for hostIndex, host := range layer.hosts {
			hostMarker := "├── "
			if hostIndex == len(layer.hosts)-1 {
				hostMarker = "└── "
			}
			fmt.Fprintf(&output, "%s%s%s\n", indent, hostMarker, describeHost(host))

			serviceIndent := indent + "│   "
			if hostMarker == "└── " {
				serviceIndent = indent + "    "
			}
			for serviceIndex, service := range host.services {
				serviceMarker := "├── "
				if serviceIndex == len(host.services)-1 {
					serviceMarker = "└── "
				}
				fmt.Fprintf(
					&output,
					"%s%s%s (%s)\n",
					serviceIndent,
					serviceMarker,
					service.port,
					service.name,
				)
			}
		}
	}
	return output.String()
}

func describeHost(host scannedHost) string {
	description := host.address.String()
	if host.hostname != "" {
		description += " (" + host.hostname + ")"
	}
	if host.os != "" {
		description += " [" + host.os + "]"
	}
	return description
}
