package system

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"strings"
	"testing"
	"time"
)

func TestShowCPUUsesNativeSystemCommands(t *testing.T) {
	runner := &fakeRunner{outputs: map[string]string{
		commandKey("sysctl", "-n", "machdep.cpu.brand_string"): "Apple M4 Max\n",
		commandKey("sysctl", "-n", "hw.ncpu"):                  "16\n",
	}}
	var out bytes.Buffer
	service := New(Options{GOOS: "darwin", Runner: runner})

	if err := service.Show(context.Background(), "cpu", &out, &bytes.Buffer{}); err != nil {
		t.Fatal(err)
	}

	want := "處理器資訊 (CPU Information)\n" +
		"- Model: Apple M4 Max\n" +
		"- Cores: 16\n"
	if got := out.String(); got != want {
		t.Fatalf("output = %q, want %q", got, want)
	}
	for _, call := range []string{
		commandKey("sysctl", "-n", "machdep.cpu.brand_string"),
		commandKey("sysctl", "-n", "hw.ncpu"),
	} {
		if !runner.called(call) {
			t.Errorf("runner did not receive %q", call)
		}
	}
}

func TestShowAllRunsEveryNativeProbeInCatalogOrder(t *testing.T) {
	runner := darwinProbeRunner()
	now := time.Date(2026, time.July, 30, 12, 0, 0, 0, time.FixedZone("UTC+8", 8*60*60))
	service := New(Options{
		GOOS:   "darwin",
		Runner: runner,
		Now:    func() time.Time { return now },
	})
	var out bytes.Buffer

	if err := service.ShowAll(context.Background(), &out, &bytes.Buffer{}); err != nil {
		t.Fatal(err)
	}

	headings := []string{
		"系統概況 (System Overview)",
		"處理器資訊 (CPU Information)",
		"記憶體 (Memory)",
		"顯示卡 (GPU)",
		"磁碟儲存 (Disk Storage)",
		"USB 裝置 (USB Devices)",
		"顯示器 (Display)",
		"正在偵測網絡介面... (Detecting network interfaces...)",
		"輸入裝置 (Input Devices)",
		"音訊裝置 (Audio Devices)",
	}
	lastIndex := -1
	for _, heading := range headings {
		index := strings.Index(out.String(), heading)
		if index < 0 {
			t.Errorf("output does not contain heading %q:\n%s", heading, out.String())
			continue
		}
		if index <= lastIndex {
			t.Errorf("heading %q is out of order:\n%s", heading, out.String())
		}
		lastIndex = index
	}

	for _, detail := range []string{
		"- OS: macOS 15.5 (arm64)",
		"- Date: 2026-07-30 12:00:00 +08:00",
		"- Total RAM: 64 GB",
		"- GPU Model: Apple M4 Max",
		"- Root Partition: 460Gi (Used: 15Gi, Free: 300Gi, Usage: 5%)",
		"- Magic Keyboard",
		"- Display: 3456 x 2234 Retina",
		"WiFi (en0): 192.168.1.20",
		"區域網路 (LAN) (en1): 10.0.0.20",
		"- Output: MacBook Pro Speakers",
	} {
		if !strings.Contains(out.String(), detail) {
			t.Errorf("output does not contain detail %q:\n%s", detail, out.String())
		}
	}
}

func TestShowRejectsUnknownInformation(t *testing.T) {
	service := New(Options{GOOS: "darwin", Runner: &fakeRunner{}})

	err := service.Show(context.Background(), "unknown", &bytes.Buffer{}, &bytes.Buffer{})
	if err == nil || !strings.Contains(err.Error(), "unknown system information") {
		t.Fatalf("error = %v, want unknown system information", err)
	}
}

func darwinProbeRunner() *fakeRunner {
	return &fakeRunner{outputs: map[string]string{
		commandKey("sw_vers", "-productName"):                  "macOS\n",
		commandKey("sw_vers", "-productVersion"):               "15.5\n",
		commandKey("uname", "-m"):                              "arm64\n",
		commandKey("sysctl", "-n", "machdep.cpu.brand_string"): "Apple M4 Max\n",
		commandKey("sysctl", "-n", "hw.ncpu"):                  "16\n",
		commandKey("sysctl", "-n", "hw.memsize"):               "68719476736\n",
		commandKey("system_profiler", "SPDisplaysDataType"):    "Graphics/Displays:\n    Apple M4 Max:\n      Chipset Model: Apple M4 Max\n      Resolution: 3456 x 2234 Retina\n",
		commandKey("df", "-h", "/"):                            "Filesystem Size Used Avail Capacity Mounted on\n/dev/disk3s1s1 460Gi 15Gi 300Gi 5% /\n",
		commandKey("system_profiler", "SPUSBDataType"):         "USB:\n    USB 3.1 Bus:\n      Magic Keyboard:\n        Product ID: 0x0267\n",
		commandKey("networksetup", "-listallhardwareports"):    "Hardware Port: Wi-Fi\nDevice: en0\nEthernet Address: aa:bb\n\nHardware Port: Thunderbolt Ethernet\nDevice: en1\nEthernet Address: cc:dd\n",
		commandKey("ipconfig", "getifaddr", "en0"):             "192.168.1.20\n",
		commandKey("ipconfig", "getifaddr", "en1"):             "10.0.0.20\n",
		commandKey("system_profiler", "SPInputDataType"):       "Input:\n    Magic Keyboard:\n      Product ID: 0x0267\n",
		commandKey("system_profiler", "SPAudioDataType"):       "Audio:\n    Devices:\n      MacBook Pro Speakers:\n        Default Output Device: Yes\n",
	}}
}

type fakeRunner struct {
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
	r.calls = append(r.calls, key)
	if err := r.errors[key]; err != nil {
		return err
	}
	if output, ok := r.outputs[key]; ok {
		if _, err := io.WriteString(out, output); err != nil {
			return err
		}
		return nil
	}
	return fmt.Errorf("unexpected command: %s", key)
}

func (r *fakeRunner) called(key string) bool {
	for _, call := range r.calls {
		if call == key {
			return true
		}
	}
	return false
}

func commandKey(name string, args ...string) string {
	return strings.Join(append([]string{name}, args...), " ")
}
