# System Information Cobra Commands Implementation Plan

> **Superseded 2026-07-30:** 本 plan 的「保留 shell adapters」決策已由
> `plans/2026-07-30-system-go-replacement.md` 取代。Command hierarchy 保留，
> runtime implementation 改為 Go-native probes。

> **For agentic workers:** REQUIRED SUB-SKILL: Use `executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 將 `bin/system/` 的 10 個 information probes 掛入 `env_setup system` Cobra hierarchy，提供 `system show` 聚合輸出，以及每個 information command 自己的 `show` child command。

**Architecture:** `bin/system/{os_info,cpu_info,mem_info,gpu_info,disk_info,usb_info,display_info,myip,input_info,audio_info}` 保留為 macOS/Linux platform adapters。`svc/system/` 負責定位與執行 scripts；`cmd/system/` 負責 Cobra hierarchy。每個 Cobra command 使用一個 package-relative command-path named file。

**Tech Stack:** Go 1.26.0、`github.com/spf13/cobra`、`github.com/bizshuk/gosdk`、Go standard library、既有 Bash probes。

## Global Constraints

- 使用繁體中文搭配 English Terminology。
- 保留 unrelated dirty worktree，尤其不修改 `bin/vscode/settings.json`。
- 維持 one command one file；檔名不重複 package prefix，並採 package-relative command path。
- `system show` 依序執行 `os`、`cpu`、`memory`、`gpu`、`disk`、`usb`、`display`、`network`、`input`、`audio`。
- `memory` 對應 `bin/system/mem_info`；`network` 對應 `bin/system/myip`。
- 每個 information parent command 只提供 command grouping；實際 probe 必須由其 `show` child 執行。
- 執行外部 probe 時必須傳遞 Cobra context，並將 stdout/stderr 導向 caller 提供的 writers。
- 不刪除既有 shell scripts 或 `system_info` symlink。

---

### Task 1: System Probe Service

**Files:**

- Create: `svc/system/catalog.go`
- Create: `svc/system/service.go`
- Create: `svc/system/service_test.go`

**Interfaces:**

- Produces:

```go
type Information struct {
	Name        string
	Script      string
	Description string
}

func Catalog() []Information
func New(systemDir string) *Service
func NewDefault() *Service
func (s *Service) Show(ctx context.Context, name string, out, errOut io.Writer) error
func (s *Service) ShowAll(ctx context.Context, out, errOut io.Writer) error
```

- [x] **Step 1: Write failing service tests**

`TestShowRunsSelectedInformationScript` 建立 temporary executable `cpu_info`，assert `Show(ctx, "cpu", ...)` 只輸出該 script 的內容。

`TestShowAllRunsEveryInformationInCatalogOrder` 在 temporary directory 建立 10 個 executable scripts，各自印出 command name，assert `ShowAll` 依 Global Constraints 的順序執行全部 probes。

`TestShowRejectsUnknownInformation` assert unknown name 回傳 error。

- [x] **Step 2: Run service tests and verify RED**

Run: `go test -count=1 ./svc/system`

Expected: FAIL because `svc/system` implementation does not exist。

- [x] **Step 3: Implement catalog and process adapter**

`Catalog` 回傳 defensive copy。`New(systemDir)` 使用明確 directory；`NewDefault()` 延遲透過 `exec.LookPath("system_info")` + `filepath.EvalSymlinks` 解析 script directory。`Show` 只執行 catalog 指定的 exact script path；`ShowAll` 逐項執行並以 `errors.Join` 回傳所有 failures。

- [x] **Step 4: Run service tests and verify GREEN**

Run: `go test -count=1 ./svc/system`

Expected: PASS。

### Task 2: Cobra Command Hierarchy

**Files:**

- Create: `cmd/system/system.go`
- Create: `cmd/system/show.go`
- Create: `cmd/system/os.go`
- Create: `cmd/system/osShow.go`
- Create: `cmd/system/cpu.go`
- Create: `cmd/system/cpuShow.go`
- Create: `cmd/system/memory.go`
- Create: `cmd/system/memoryShow.go`
- Create: `cmd/system/gpu.go`
- Create: `cmd/system/gpuShow.go`
- Create: `cmd/system/disk.go`
- Create: `cmd/system/diskShow.go`
- Create: `cmd/system/usb.go`
- Create: `cmd/system/usbShow.go`
- Create: `cmd/system/display.go`
- Create: `cmd/system/displayShow.go`
- Create: `cmd/system/network.go`
- Create: `cmd/system/networkShow.go`
- Create: `cmd/system/input.go`
- Create: `cmd/system/inputShow.go`
- Create: `cmd/system/audio.go`
- Create: `cmd/system/audioShow.go`
- Create: `cmd/system/system_test.go`
- Modify: `cmd/root.go`
- Modify: `cmd/root_test.go`
- Modify: `cmd/command_file_test.go`

**Interfaces:**

- Consumes: `system.Service.Show`、`system.Service.ShowAll`。
- Produces:

```go
func systemcmd.NewCommand(service *system.Service, out, errOut io.Writer) *cobra.Command
func NewRootCommand(cleanupService *cleanup.Service, systemService *system.Service, in io.Reader, out, errOut io.Writer) *cobra.Command
```

- [x] **Step 1: Write failing command tests**

`TestCommandContainsSystemShowAndInformationShowCommands` assert 以下 paths 全部存在：

```text
show
os show
cpu show
memory show
gpu show
disk show
usb show
display show
network show
input show
audio show
```

`TestInformationShowExecutesSelectedProbe` 透過 temporary executable `cpu_info` 執行 `cpu show`，assert stdout。

更新 `TestRootContainsDomainSubcommands`，assert root 包含 `cleanup`、`backup`、`system`。更新 architecture contract，列入全部 22 個 `cmd/system` production command files。

- [x] **Step 2: Run command tests and verify RED**

Run: `go test -count=1 ./cmd/...`

Expected: FAIL because `cmd/system` hierarchy and root wiring do not exist。

- [x] **Step 3: Implement one command per file**

`system.go` 建立 parent 並註冊 `system show` 及 10 個 information parents。每個 information parent 只註冊自己的 `show` child；每個 `show` 使用 `RunE` 將 `command.Context()` 傳給 service。Parent commands 無參數時顯示 help。

- [x] **Step 4: Wire default service into root**

`Execute` 使用 `system.NewDefault()`；root constructor 注入 service，以建立 fresh Cobra tree 並避免 package-level flag state。

- [x] **Step 5: Run command tests and verify GREEN**

Run: `go test -count=1 ./cmd/...`

Expected: PASS。

### Task 3: Canonical Documentation and Verification

**Files:**

- Modify: `README.md`
- Modify: `CLAUDE.md`
- Modify: `README.todo`
- Modify: `bin/README.md`
- Modify: `bin/system/README.md`
- Modify: `docs/bin_index.md`
- Modify: `docs/terminology.md`

**Interfaces:**

- Documents:

```text
env_setup system show
env_setup system os show
env_setup system cpu show
env_setup system memory show
env_setup system gpu show
env_setup system disk show
env_setup system usb show
env_setup system display show
env_setup system network show
env_setup system input show
env_setup system audio show
```

- [x] **Step 1: Update canonical docs**

`README.md` 說明 why/how-to；`CLAUDE.md` 單一擁有 package tree、script ownership 與 naming contract；`bin/system/README.md` 與 `docs/bin_index.md` 標示 shell entry points 為 platform adapters；`docs/terminology.md` 定義 Information Command、Aggregate Show 與 Platform Adapter；`README.todo` 記錄完成項。

- [x] **Step 2: Format and run full static verification**

Run:

```bash
gofmt -w main.go cmd model svc
go mod tidy
git diff --check
go test -count=1 ./...
go test -race -count=1 ./...
go vet ./...
go build ./...
golangci-lint run --no-config ./...
```

Expected: all commands exit 0。

- [x] **Step 3: Install and run live CLI verification**

Run:

```bash
./build.sh
env_setup system --help
env_setup system show
env_setup system cpu show
env_setup system network show
```

Expected: help 列出 `show` 與 10 個 information commands；aggregate 和 individual outputs 均來自既有 scripts。
