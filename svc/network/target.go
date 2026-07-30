package network

import (
	"bufio"
	"context"
	"fmt"
	"io"
	"net/netip"
	"regexp"
	"strings"
	"sync"
)

const (
	defaultTargetCIDR = "192.168.0.0/24"
	maxPingPrefixBits = 24
	pingWorkerCount   = 32
)

var nmapGrepableHostPattern = regexp.MustCompile(
	`^Host:\s+(\S+)\s+\(([^)]*)\)\s+Status:\s+Up\s*$`,
)

// TargetOptions configures a target network discovery scan.
type TargetOptions struct {
	CIDR string
}

type targetHost struct {
	address  string
	hostname string
}

// ScanTarget discovers live hosts in one IPv4 CIDR.
func (s *Service) ScanTarget(
	ctx context.Context,
	out io.Writer,
	errOut io.Writer,
	options TargetOptions,
) error {
	target, prefix, err := parseTargetPrefix(options.CIDR)
	if err != nil {
		return err
	}
	if _, err := fmt.Fprintf(out, "正在掃描網路: %s (Scanning network...)\n", target); err != nil {
		return fmt.Errorf("write target scan header: %w", err)
	}

	if _, err := s.lookPath("nmap"); err == nil {
		if err := s.scanTargetWithNmap(ctx, out, errOut, target); err != nil {
			return err
		}
	} else {
		if prefix.Bits() < maxPingPrefixBits {
			return fmt.Errorf(
				"nmap is required to scan %s; ping fallback is limited to /%d or smaller networks",
				target,
				maxPingPrefixBits,
			)
		}
		if err := s.scanTargetWithPing(ctx, out, prefix); err != nil {
			return err
		}
	}

	if _, err := fmt.Fprintln(out, "掃描完成。(Scan completed.)"); err != nil {
		return fmt.Errorf("write target scan completion: %w", err)
	}
	return nil
}

func parseTargetPrefix(rawTarget string) (string, netip.Prefix, error) {
	target := strings.TrimSpace(rawTarget)
	if target == "" {
		target = defaultTargetCIDR
	}
	if target == "192.168.0.0" {
		target = "192.168.0.0/16"
	}
	prefix, err := netip.ParsePrefix(target)
	if err != nil || !prefix.Addr().Is4() {
		return "", netip.Prefix{}, fmt.Errorf("invalid IPv4 CIDR %q", target)
	}
	return target, prefix, nil
}

func (s *Service) scanTargetWithNmap(
	ctx context.Context,
	out io.Writer,
	errOut io.Writer,
	target string,
) error {
	output, err := s.runOutput(
		ctx,
		errOut,
		"nmap",
		"-sn",
		"-T4",
		"--min-parallelism",
		"100",
		"--max-retries",
		"1",
		target,
		"-oG",
		"-",
	)
	if err != nil {
		return err
	}
	for _, host := range parseNmapGrepableHosts(output) {
		if err := writeTargetHost(out, host); err != nil {
			return err
		}
	}
	return nil
}

func parseNmapGrepableHosts(output string) []targetHost {
	var hosts []targetHost
	scanner := bufio.NewScanner(strings.NewReader(output))
	for scanner.Scan() {
		matches := nmapGrepableHostPattern.FindStringSubmatch(scanner.Text())
		if len(matches) != 3 {
			continue
		}
		hosts = append(hosts, targetHost{
			address:  matches[1],
			hostname: matches[2],
		})
	}
	return hosts
}

func (s *Service) scanTargetWithPing(
	ctx context.Context,
	out io.Writer,
	prefix netip.Prefix,
) error {
	if _, err := s.lookPath("ping"); err != nil {
		return fmt.Errorf("ping fallback is unavailable: %w", err)
	}
	if _, err := fmt.Fprintln(out, "未找到 nmap，改用 bounded ping fallback。"); err != nil {
		return fmt.Errorf("write ping fallback notice: %w", err)
	}

	addresses := usableAddresses(prefix)
	reachable := make([]bool, len(addresses))
	jobs := make(chan int, len(addresses))
	for index := range addresses {
		jobs <- index
	}
	close(jobs)

	workers := min(pingWorkerCount, len(addresses))
	var waitGroup sync.WaitGroup
	waitGroup.Add(workers)
	for range workers {
		go func() {
			defer waitGroup.Done()
			for index := range jobs {
				args := s.pingArguments(addresses[index])
				reachable[index] = s.runner.Run(
					ctx,
					nil,
					io.Discard,
					io.Discard,
					"ping",
					args...,
				) == nil
			}
		}()
	}
	waitGroup.Wait()
	if err := ctx.Err(); err != nil {
		return fmt.Errorf("ping fallback: %w", err)
	}

	for index, address := range addresses {
		if !reachable[index] {
			continue
		}
		if err := writeTargetHost(out, targetHost{address: address.String()}); err != nil {
			return err
		}
	}
	return nil
}

func (s *Service) pingArguments(address netip.Addr) []string {
	if s.goos == "darwin" {
		return []string{"-c", "1", "-W", "1000", address.String()}
	}
	return []string{"-c", "1", "-W", "1", address.String()}
}

func usableAddresses(prefix netip.Prefix) []netip.Addr {
	networkAddress := prefix.Masked().Addr()
	var addresses []netip.Addr
	for address := networkAddress.Next(); prefix.Contains(address.Next()); address = address.Next() {
		addresses = append(addresses, address)
	}
	return addresses
}

func writeTargetHost(out io.Writer, host targetHost) error {
	hostname := host.hostname
	if hostname == "" || hostname == "unknown" {
		hostname = "(未知/Unknown)"
	}
	if _, err := fmt.Fprintf(out, "✅ 發現主機: %s\t名稱: %s\n", host.address, hostname); err != nil {
		return fmt.Errorf("write target host: %w", err)
	}
	return nil
}
