package network

import (
	"context"
	"errors"
	"io"
	"net/netip"
	"path/filepath"
	"strings"
	"testing"

	networksvc "github.com/bizshuk/env_setup/svc/network"
)

func TestCommandContainsPrivateAndTargetCommands(t *testing.T) {
	command := NewCommand(
		networksvc.New(networksvc.Options{Runner: &commandRunner{}}),
		io.Discard,
		io.Discard,
	)

	for _, path := range [][]string{{"private"}, {"target"}} {
		found, remaining, err := command.Find(path)
		if err != nil {
			t.Errorf("find %q: %v", strings.Join(path, " "), err)
			continue
		}
		if len(remaining) != 0 {
			t.Errorf("find %q left arguments %v", strings.Join(path, " "), remaining)
			continue
		}
		if found.Name() != path[0] {
			t.Errorf("find %q returned %q", strings.Join(path, " "), found.Name())
		}
	}
}

func TestTargetCommandForwardsCIDR(t *testing.T) {
	runner := &commandRunner{outputs: map[string]string{
		"nmap -sn -T4 --min-parallelism 100 --max-retries 1 192.168.2.0/30 -oG -": "",
	}}
	service := networksvc.New(networksvc.Options{
		Runner:   runner,
		LookPath: func(string) (string, error) { return "/usr/local/bin/nmap", nil },
	})
	command := NewCommand(service, io.Discard, io.Discard)
	command.SetArgs([]string{"target", "192.168.2.0/30"})

	if err := command.Execute(); err != nil {
		t.Fatal(err)
	}
	if !runner.called("nmap -sn -T4 --min-parallelism 100 --max-retries 1 192.168.2.0/30 -oG -") {
		t.Fatalf("target command calls = %v", runner.calls)
	}
}

func TestPrivateCommandForwardsTargetAndOutputFlag(t *testing.T) {
	outputPath := filepath.Join(t.TempDir(), "topology.txt")
	runner := &commandRunner{outputs: map[string]string{
		"traceroute -n -m 20 -q 1 1.1.1.1": "" +
			"traceroute to 1.1.1.1 (1.1.1.1), 20 hops max\n" +
			" 1  192.168.1.1  1.0 ms\n" +
			" 2  1.1.1.1  2.0 ms\n",
		"nmap -F -n 192.168.1.0/24": "",
	}}
	service := networksvc.New(networksvc.Options{
		Runner: runner,
		LookPath: func(name string) (string, error) {
			return "/usr/local/bin/" + name, nil
		},
		Hostname: func() (string, error) {
			return "test.local", nil
		},
		LocalAddresses: func() ([]netip.Addr, error) {
			return []netip.Addr{netip.MustParseAddr("192.168.1.20")}, nil
		},
	})
	command := NewCommand(service, io.Discard, io.Discard)
	command.SetArgs([]string{"private", "1.1.1.1", "--output", outputPath})

	if err := command.Execute(); err != nil {
		t.Fatal(err)
	}
	if !runner.called("traceroute -n -m 20 -q 1 1.1.1.1") {
		t.Fatalf("private command calls = %v", runner.calls)
	}
}

type commandRunner struct {
	outputs map[string]string
	calls   []string
}

func (r *commandRunner) Run(
	_ context.Context,
	_ io.Reader,
	out io.Writer,
	_ io.Writer,
	name string,
	args ...string,
) error {
	key := strings.Join(append([]string{name}, args...), " ")
	r.calls = append(r.calls, key)
	output, ok := r.outputs[key]
	if !ok {
		return errors.New("unexpected command: " + key)
	}
	_, err := io.WriteString(out, output)
	return err
}

func (r *commandRunner) called(want string) bool {
	for _, call := range r.calls {
		if call == want {
			return true
		}
	}
	return false
}
