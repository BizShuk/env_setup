package system

import (
	"bytes"
	"context"
	"io"
	"strings"
	"testing"

	systemsvc "github.com/bizshuk/env_setup/svc/system"
)

func TestCommandContainsSystemShowAndInformationShowCommands(t *testing.T) {
	service := systemsvc.New(systemsvc.Options{GOOS: "darwin", Runner: commandRunner{}})
	command := NewCommand(service, &bytes.Buffer{}, &bytes.Buffer{})
	paths := [][]string{
		{"show"},
		{"os", "show"},
		{"cpu", "show"},
		{"memory", "show"},
		{"gpu", "show"},
		{"disk", "show"},
		{"usb", "show"},
		{"display", "show"},
		{"network", "show"},
		{"input", "show"},
		{"audio", "show"},
	}

	for _, path := range paths {
		found, remaining, err := command.Find(path)
		if err != nil {
			t.Errorf("find %q: %v", strings.Join(path, " "), err)
			continue
		}
		if len(remaining) != 0 {
			t.Errorf("find %q left arguments %v", strings.Join(path, " "), remaining)
			continue
		}
		if found.Name() != "show" {
			t.Errorf("find %q returned %q, want show", strings.Join(path, " "), found.Name())
		}
	}
}

func TestInformationShowExecutesSelectedProbe(t *testing.T) {
	var out bytes.Buffer
	service := systemsvc.New(systemsvc.Options{
		GOOS: "darwin",
		Runner: commandRunner{outputs: map[string]string{
			"sysctl -n machdep.cpu.brand_string": "Selected CPU\n",
			"sysctl -n hw.ncpu":                  "12\n",
		}},
	})
	command := NewCommand(service, &out, &bytes.Buffer{})
	command.SetArgs([]string{"cpu", "show"})

	if err := command.Execute(); err != nil {
		t.Fatal(err)
	}
	want := "處理器資訊 (CPU Information)\n- Model: Selected CPU\n- Cores: 12"
	if got := strings.TrimSpace(out.String()); got != want {
		t.Fatalf("output = %q, want %q", got, want)
	}
}

type commandRunner struct {
	outputs map[string]string
}

func (r commandRunner) Run(
	_ context.Context,
	_ io.Reader,
	out io.Writer,
	_ io.Writer,
	name string,
	args ...string,
) error {
	_, err := io.WriteString(out, r.outputs[strings.Join(append([]string{name}, args...), " ")])
	return err
}
