package network

import (
	"bytes"
	"context"
	"errors"
	"io"
	"strings"
	"sync"
	"testing"
)

func TestScanTargetRunsNmapAndPrintsLiveHosts(t *testing.T) {
	runner := &fakeRunner{outputs: map[string]string{
		commandKey(
			"nmap",
			"-sn",
			"-T4",
			"--min-parallelism",
			"100",
			"--max-retries",
			"1",
			"192.168.1.0/24",
			"-oG",
			"-",
		): "Host: 192.168.1.1 (router.local)\tStatus: Up\n" +
			"Host: 192.168.1.20 ()\tStatus: Up\n" +
			"Host: 192.168.1.30 ()\tStatus: Down\n",
	}}
	service := New(Options{
		Runner: runner,
		LookPath: func(name string) (string, error) {
			if name != "nmap" {
				t.Fatalf("LookPath(%q), want nmap", name)
			}
			return "/opt/homebrew/bin/nmap", nil
		},
	})
	var out bytes.Buffer

	err := service.ScanTarget(
		context.Background(),
		&out,
		&bytes.Buffer{},
		TargetOptions{CIDR: "192.168.1.0/24"},
	)
	if err != nil {
		t.Fatal(err)
	}

	for _, line := range []string{
		"正在掃描網路: 192.168.1.0/24 (Scanning network...)",
		"發現主機: 192.168.1.1",
		"名稱: router.local",
		"發現主機: 192.168.1.20",
		"名稱: (未知/Unknown)",
		"掃描完成。(Scan completed.)",
	} {
		if !strings.Contains(out.String(), line) {
			t.Errorf("output does not contain %q:\n%s", line, out.String())
		}
	}
	if strings.Contains(out.String(), "192.168.1.30") {
		t.Errorf("output contains down host:\n%s", out.String())
	}
}

func TestScanTargetPreservesLegacyDefaultNetworkShorthand(t *testing.T) {
	runner := &fakeRunner{outputs: map[string]string{
		commandKey(
			"nmap",
			"-sn",
			"-T4",
			"--min-parallelism",
			"100",
			"--max-retries",
			"1",
			"192.168.0.0/16",
			"-oG",
			"-",
		): "",
	}}
	service := New(Options{
		Runner:   runner,
		LookPath: func(string) (string, error) { return "/usr/local/bin/nmap", nil },
	})

	err := service.ScanTarget(
		context.Background(),
		io.Discard,
		io.Discard,
		TargetOptions{CIDR: "192.168.0.0"},
	)
	if err != nil {
		t.Fatal(err)
	}
}

func TestScanTargetFallsBackToPingForSmallCIDR(t *testing.T) {
	runner := &fakeRunner{
		outputs: map[string]string{
			commandKey("ping", "-c", "1", "-W", "1000", "192.168.1.1"): "",
		},
		errors: map[string]error{
			commandKey("ping", "-c", "1", "-W", "1000", "192.168.1.2"): errors.New("unreachable"),
		},
	}
	service := New(Options{
		GOOS:   "darwin",
		Runner: runner,
		LookPath: func(name string) (string, error) {
			switch name {
			case "nmap":
				return "", errors.New("not found")
			case "ping":
				return "/sbin/ping", nil
			default:
				t.Fatalf("unexpected LookPath(%q)", name)
				return "", nil
			}
		},
	})
	var out bytes.Buffer

	err := service.ScanTarget(
		context.Background(),
		&out,
		io.Discard,
		TargetOptions{CIDR: "192.168.1.0/30"},
	)
	if err != nil {
		t.Fatal(err)
	}

	if !strings.Contains(out.String(), "發現主機: 192.168.1.1") {
		t.Errorf("output does not contain live ping host:\n%s", out.String())
	}
	if strings.Contains(out.String(), "發現主機: 192.168.1.2") {
		t.Errorf("output contains unreachable ping host:\n%s", out.String())
	}
}

func TestScanTargetRejectsUnsafeWidePingFallback(t *testing.T) {
	service := New(Options{
		Runner: &fakeRunner{},
		LookPath: func(name string) (string, error) {
			return "", errors.New("not found: " + name)
		},
	})

	err := service.ScanTarget(
		context.Background(),
		io.Discard,
		io.Discard,
		TargetOptions{CIDR: "10.0.0.0/8"},
	)
	if err == nil || !strings.Contains(err.Error(), "nmap is required") {
		t.Fatalf("error = %v, want nmap-required error", err)
	}
}

type fakeRunner struct {
	mu      sync.Mutex
	outputs map[string]string
	errors  map[string]error
	calls   []string
}

func (r *fakeRunner) Run(
	_ context.Context,
	_ io.Reader,
	out io.Writer,
	_ io.Writer,
	name string,
	args ...string,
) error {
	key := commandKey(name, args...)
	r.mu.Lock()
	r.calls = append(r.calls, key)
	r.mu.Unlock()
	if err := r.errors[key]; err != nil {
		return err
	}
	output, ok := r.outputs[key]
	if !ok {
		return errors.New("unexpected command: " + key)
	}
	_, err := io.WriteString(out, output)
	return err
}

func commandKey(name string, args ...string) string {
	return strings.Join(append([]string{name}, args...), " ")
}
