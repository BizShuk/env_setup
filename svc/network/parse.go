package network

import (
	"bufio"
	"net/netip"
	"regexp"
	"strings"
)

var (
	ipv4Pattern       = regexp.MustCompile(`(?:\d{1,3}\.){3}\d{1,3}`)
	carrierGradeNAT   = netip.MustParsePrefix("100.64.0.0/10")
	nmapReportPrefix  = "Nmap scan report for "
	nmapOSLinePattern = regexp.MustCompile(`^(?:OS details|Running):\s*(.+)$`)
)

type scannedService struct {
	port string
	name string
}

type scannedHost struct {
	address  netip.Addr
	hostname string
	os       string
	services []scannedService
}

func parsePrivateHops(output string) []netip.Addr {
	var hops []netip.Addr
	scanner := bufio.NewScanner(strings.NewReader(output))
	firstLine := true
	for scanner.Scan() {
		if firstLine {
			firstLine = false
			continue
		}
		rawAddress := ipv4Pattern.FindString(scanner.Text())
		if rawAddress == "" {
			continue
		}
		address, err := netip.ParseAddr(rawAddress)
		if err != nil {
			continue
		}
		if !isPrivateRouteAddress(address) {
			break
		}
		hops = append(hops, address)
	}
	return hops
}

func isPrivateRouteAddress(address netip.Addr) bool {
	return address.Is4() && (address.IsPrivate() || carrierGradeNAT.Contains(address))
}

func parseNmapHosts(output string) []scannedHost {
	var hosts []scannedHost
	var current *scannedHost
	flush := func() {
		if current != nil && current.address.IsValid() {
			hosts = append(hosts, *current)
		}
		current = nil
	}

	scanner := bufio.NewScanner(strings.NewReader(output))
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if strings.HasPrefix(line, nmapReportPrefix) {
			flush()
			host, ok := parseNmapReport(strings.TrimPrefix(line, nmapReportPrefix))
			if ok {
				current = &host
			}
			continue
		}
		if current == nil {
			continue
		}
		if matches := nmapOSLinePattern.FindStringSubmatch(line); len(matches) == 2 {
			current.os = strings.TrimSpace(matches[1])
			continue
		}
		fields := strings.Fields(line)
		if len(fields) >= 3 && fields[1] == "open" && strings.Contains(fields[0], "/") {
			current.services = append(current.services, scannedService{
				port: fields[0],
				name: fields[2],
			})
		}
	}
	flush()
	return hosts
}

func parseNmapReport(report string) (scannedHost, bool) {
	report = strings.TrimSpace(report)
	if openParenthesis := strings.LastIndex(report, " ("); openParenthesis >= 0 &&
		strings.HasSuffix(report, ")") {
		address, err := netip.ParseAddr(report[openParenthesis+2 : len(report)-1])
		if err != nil {
			return scannedHost{}, false
		}
		return scannedHost{
			address:  address,
			hostname: strings.TrimSpace(report[:openParenthesis]),
		}, true
	}
	address, err := netip.ParseAddr(report)
	if err != nil {
		return scannedHost{}, false
	}
	return scannedHost{address: address}, true
}
