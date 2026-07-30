package network

import (
	"bytes"
	"context"
	"errors"
	"io"
	"net/netip"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestScanPrivateWritesRouteTopology(t *testing.T) {
	outputPath := filepath.Join(t.TempDir(), "network.topo")
	runner := &fakeRunner{outputs: map[string]string{
		commandKey("traceroute", "-n", "-m", "20", "-q", "1", "8.8.8.8"): "" +
			"traceroute to 8.8.8.8 (8.8.8.8), 20 hops max\n" +
			" 1  192.168.1.1  1.01 ms\n" +
			" 2  100.64.1.1  2.02 ms\n" +
			" 3  8.8.8.8  3.03 ms\n",
		commandKey("nmap", "-F", "-n", "100.64.1.0/24"): "" +
			"Nmap scan report for 100.64.1.1\n" +
			"Host is up.\n" +
			"Nmap scan report for upstream-device (100.64.1.10)\n" +
			"Host is up.\n" +
			"PORT   STATE SERVICE\n" +
			"80/tcp open  http\n",
		commandKey("nmap", "-F", "-n", "192.168.1.0/24"): "" +
			"Nmap scan report for 192.168.1.1\n" +
			"Host is up.\n" +
			"Nmap scan report for nas.local (192.168.1.50)\n" +
			"Host is up.\n" +
			"Running: Linux 5.X\n" +
			"PORT    STATE SERVICE\n" +
			"22/tcp  open  ssh\n" +
			"443/tcp open  https\n",
	}}
	service := New(Options{
		Runner: runner,
		LookPath: func(name string) (string, error) {
			switch name {
			case "traceroute", "nmap":
				return "/usr/local/bin/" + name, nil
			default:
				return "", errors.New("unexpected dependency: " + name)
			}
		},
		Hostname: func() (string, error) {
			return "mac-mini.local", nil
		},
		LocalAddresses: func() ([]netip.Addr, error) {
			return []netip.Addr{netip.MustParseAddr("192.168.1.20")}, nil
		},
	})
	var out bytes.Buffer

	err := service.ScanPrivate(
		context.Background(),
		&out,
		&bytes.Buffer{},
		PrivateOptions{Target: "8.8.8.8", OutputPath: outputPath},
	)
	if err != nil {
		t.Fatal(err)
	}

	content, err := os.ReadFile(outputPath)
	if err != nil {
		t.Fatal(err)
	}
	topology := string(content)
	for _, line := range []string{
		"本地主機 (Local Host): 192.168.1.20 (mac-mini)",
		"100.64.1.0/24",
		"100.64.1.10 (upstream-device)",
		"80/tcp (http)",
		"192.168.1.0/24",
		"192.168.1.50 (nas.local) [Linux 5.X]",
		"22/tcp (ssh)",
		"443/tcp (https)",
	} {
		if !strings.Contains(topology, line) {
			t.Errorf("topology does not contain %q:\n%s", line, topology)
		}
	}
	if strings.Index(topology, "100.64.1.0/24") > strings.Index(topology, "192.168.1.0/24") {
		t.Errorf("topology subnet order is not public-to-local:\n%s", topology)
	}
	for _, excluded := range []string{"100.64.1.1\n", "192.168.1.1\n"} {
		if strings.Contains(topology, excluded) {
			t.Errorf("topology contains route hop %q:\n%s", excluded, topology)
		}
	}
	if !strings.Contains(out.String(), "結果已儲存至: "+outputPath) {
		t.Errorf("stdout does not identify output path:\n%s", out.String())
	}
	if !strings.Contains(out.String(), topology) {
		t.Errorf("stdout does not include topology:\n%s", out.String())
	}
}

func TestPrivateHopsStopsAtFirstPublicAddress(t *testing.T) {
	output := "" +
		"traceroute to example.test (203.0.113.10), 20 hops max\n" +
		" 1  10.0.0.1  1.0 ms\n" +
		" 2  * * *\n" +
		" 3  172.16.0.1  2.0 ms\n" +
		" 4  203.0.113.1  3.0 ms\n" +
		" 5  192.168.99.1  4.0 ms\n"

	got := parsePrivateHops(output)
	want := []netip.Addr{
		netip.MustParseAddr("10.0.0.1"),
		netip.MustParseAddr("172.16.0.1"),
	}
	if len(got) != len(want) {
		t.Fatalf("private hops = %v, want %v", got, want)
	}
	for index := range want {
		if got[index] != want[index] {
			t.Errorf("private hop %d = %s, want %s", index, got[index], want[index])
		}
	}
}

func TestScanPrivateRequiresTracerouteAndNmap(t *testing.T) {
	service := New(Options{
		Runner: &fakeRunner{},
		LookPath: func(name string) (string, error) {
			if name == "traceroute" {
				return "", errors.New("not found")
			}
			return "/usr/local/bin/" + name, nil
		},
	})

	err := service.ScanPrivate(
		context.Background(),
		io.Discard,
		io.Discard,
		PrivateOptions{Target: "8.8.8.8", OutputPath: filepath.Join(t.TempDir(), "network.topo")},
	)
	if err == nil || !strings.Contains(err.Error(), "traceroute is required") {
		t.Fatalf("error = %v, want traceroute-required error", err)
	}
}
