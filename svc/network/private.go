package network

import (
	"context"
	"fmt"
	"io"
	"net/netip"
	"os"
	"strings"
)

const (
	defaultPrivateTarget = "8.8.8.8"
	defaultTopologyPath  = "network.topo"
)

// PrivateOptions configures a private-route topology scan.
type PrivateOptions struct {
	Target     string
	OutputPath string
}

// ScanPrivate traces private route layers and writes their scanned topology.
func (s *Service) ScanPrivate(
	ctx context.Context,
	out io.Writer,
	errOut io.Writer,
	options PrivateOptions,
) error {
	for _, dependency := range []string{"traceroute", "nmap"} {
		if _, err := s.lookPath(dependency); err != nil {
			return fmt.Errorf("%s is required for private network scan: %w", dependency, err)
		}
	}

	target := strings.TrimSpace(options.Target)
	if target == "" {
		target = defaultPrivateTarget
	}
	outputPath := strings.TrimSpace(options.OutputPath)
	if outputPath == "" {
		outputPath = defaultTopologyPath
	}

	localAddresses, err := s.localAddresses()
	if err != nil {
		return fmt.Errorf("read local IPv4 addresses: %w", err)
	}
	localAddress := netip.MustParseAddr("127.0.0.1")
	if len(localAddresses) > 0 {
		localAddress = localAddresses[0]
	}
	hostname, err := s.hostname()
	if err != nil {
		return fmt.Errorf("read local hostname: %w", err)
	}

	if _, err := fmt.Fprintln(out, "正在分析網路路徑... (Analyzing network path...)"); err != nil {
		return fmt.Errorf("write private scan header: %w", err)
	}
	tracerouteOutput, err := s.runOutput(
		ctx,
		errOut,
		"traceroute",
		"-n",
		"-m",
		"20",
		"-q",
		"1",
		target,
	)
	if err != nil {
		return err
	}
	hops := includeLocalNetworks(parsePrivateHops(tracerouteOutput), localAddresses)
	layers := topologyLayers(hops)
	if len(layers) == 0 {
		return fmt.Errorf("no private network layers found on route to %s", target)
	}

	for index := range layers {
		if _, err := fmt.Fprintf(
			errOut,
			"正在掃描網段 %s... (Scanning subnet...)\n",
			layers[index].prefix,
		); err != nil {
			return fmt.Errorf("write private scan progress: %w", err)
		}
		nmapOutput, err := s.runOutput(
			ctx,
			errOut,
			"nmap",
			"-F",
			"-n",
			layers[index].prefix.String(),
		)
		if err != nil {
			return err
		}
		nextHop := netip.Addr{}
		if index+1 < len(layers) {
			nextHop = layers[index+1].hop
		}
		layers[index].hosts = filterTopologyHosts(
			parseNmapHosts(nmapOutput),
			layers[index].hop,
			nextHop,
		)
	}

	topology := renderTopology(localAddress, hostname, layers)
	if err := os.WriteFile(outputPath, []byte(topology), 0o644); err != nil {
		return fmt.Errorf("write topology %s: %w", outputPath, err)
	}
	if _, err := fmt.Fprintf(
		out,
		"分析完成！結果已儲存至: %s\n%s",
		outputPath,
		topology,
	); err != nil {
		return fmt.Errorf("write private scan result: %w", err)
	}
	return nil
}

func includeLocalNetworks(hops, localAddresses []netip.Addr) []netip.Addr {
	present := make(map[netip.Prefix]bool, len(hops))
	for _, hop := range hops {
		present[ipv4Subnet(hop)] = true
	}

	var missingLocal []netip.Addr
	for _, address := range localAddresses {
		if !isPrivateRouteAddress(address) {
			continue
		}
		prefix := ipv4Subnet(address)
		if present[prefix] {
			continue
		}
		present[prefix] = true
		missingLocal = append(missingLocal, address)
	}
	return append(missingLocal, hops...)
}

func topologyLayers(hops []netip.Addr) []topologyLayer {
	seen := make(map[netip.Prefix]bool, len(hops))
	var layers []topologyLayer
	for index := len(hops) - 1; index >= 0; index-- {
		prefix := ipv4Subnet(hops[index])
		if seen[prefix] {
			continue
		}
		seen[prefix] = true
		layers = append(layers, topologyLayer{
			hop:    hops[index],
			prefix: prefix,
		})
	}
	return layers
}

func ipv4Subnet(address netip.Addr) netip.Prefix {
	return netip.PrefixFrom(address, 24).Masked()
}

func filterTopologyHosts(hosts []scannedHost, currentHop, nextHop netip.Addr) []scannedHost {
	var filtered []scannedHost
	for _, host := range hosts {
		if host.address == currentHop ||
			host.address == nextHop ||
			host.address.IsLoopback() {
			continue
		}
		filtered = append(filtered, host)
	}
	return filtered
}
