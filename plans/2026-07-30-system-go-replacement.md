# System Go Replacement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `test-driven-development` and execute this plan inline, task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 讓 `env_setup system` 直接提供 cross-platform system information，不再執行 `bin/system/` shell adapters，並在保留其他有效工具的前提下移除整個 `bin/system/` folder。

**Architecture:** `svc/system` 以一個小型 `Runner` interface 封裝 external commands，各 information probe 由自己的 Go file 負責 platform selection、output parsing 與 presentation。`cmd/system` hierarchy 延伸 `system disk verify <volume-path>` 擁有 F3 media verification；package/IDE manifests 由 `env_setup dump` 擁有，其他非 information scripts 依 domain 搬到 `bin/disk/`、`bin/codex/` 與 `pkg/sysctl/`。

**Tech Stack:** Go 1.26.0、`github.com/spf13/cobra`、`github.com/bizshuk/gosdk`、Go standard library、macOS/Linux system commands。

## Global Constraints

- 使用繁體中文搭配 English Terminology。
- 保留 unrelated dirty worktree，尤其不修改 `bin/vscode/settings.json`。
- 維持 one command one file 與 one file one responsibility。
- `system show` 依序執行 `os`、`cpu`、`memory`、`gpu`、`disk`、`usb`、`display`、`network`、`input`、`audio`。
- `system <information> show` 不得依賴 repo path、`PATH` 中的 `system_info` symlink 或 `bin/system/`。
- macOS/Linux 差異由 `svc/system` 擁有；external command errors 必須以 `%w` 保留 error chain。
- `bin/system/` 內非 information 工具必須搬遷，不得 silently delete。
- 不建立新的 compatibility wrappers；已由 Cobra 取代的 `system_info` root symlink 直接移除。
- 不 commit、不 stage、不修改使用者既有的 unrelated changes。

---

### Task 1: Native System Probe Runtime

**Files:**

- Modify: `svc/system/catalog.go`
- Replace: `svc/system/service.go`
- Create: `svc/system/runner.go`
- Create: `svc/system/os.go`
- Create: `svc/system/cpu.go`
- Create: `svc/system/memory.go`
- Create: `svc/system/gpu.go`
- Create: `svc/system/disk.go`
- Create: `svc/system/usb.go`
- Create: `svc/system/display.go`
- Create: `svc/system/network.go`
- Create: `svc/system/input.go`
- Create: `svc/system/audio.go`
- Modify: `svc/system/service_test.go`

**Interfaces:**

- `type Runner interface { Run(context.Context, io.Reader, io.Writer, io.Writer, string, ...string) error }`
- `type Options struct { GOOS string; Runner Runner; Now func() time.Time; ReadFile func(string) ([]byte, error) }`
- `func New(Options) *Service`
- `func NewDefault() *Service`
- `func (s *Service) Show(context.Context, string, io.Writer, io.Writer) error`
- `func (s *Service) ShowAll(context.Context, io.Writer, io.Writer) error`

- [x] **Step 1: Write failing direct-runner tests**

Replace script-fixture tests with a fake `Runner` and assert that `Show("cpu")` renders the model and core count returned by `sysctl`. Add table tests for each catalog item and aggregate order.

- [x] **Step 2: Verify RED**

Run:

```bash
go test -count=1 ./svc/system
```

Expected: compile failure because `Options` and runner-based `New` do not exist.

- [x] **Step 3: Implement minimal runner and probe files**

Each catalog entry stores an unexported method expression:

```go
type probe func(*Service, context.Context, io.Writer, io.Writer) error

type Information struct {
    Name        string
    Description string
    show        probe
}
```

Each probe runs only the platform commands it needs and parses output in Go. `Show` selects the catalog entry and invokes `information.show`.

- [x] **Step 4: Verify GREEN**

Run:

```bash
go test -count=1 ./svc/system
```

Expected: all native probe tests pass without creating shell scripts.

---

### Task 2: Cobra Wiring Without Adapter Paths

**Files:**

- Modify: `cmd/system/system_test.go`
- Modify: `cmd/root_test.go`
- Modify: `cmd/command_file_test.go`

**Interfaces:**

- Consumes `systemsvc.New(systemsvc.Options{...})`.
- Keeps all existing command paths unchanged.

- [x] **Step 1: Write failing command execution test**

Construct a service with a fake runner, execute `system cpu show`, and assert the native probe output. Add a repository contract asserting `bin/system` does not exist.

- [x] **Step 2: Verify RED**

Run:

```bash
go test -count=1 ./cmd/...
```

Expected: failure while the tests still call the removed directory-based constructor and while `bin/system/` exists.

- [x] **Step 3: Update test wiring**

Use:

```go
systemsvc.New(systemsvc.Options{
    GOOS:  "darwin",
    Runner: fakeRunner,
})
```

No Cobra command file is added or renamed.

- [x] **Step 4: Verify command behavior**

Run:

```bash
go test -count=1 ./cmd/...
```

The structure test remains RED until Task 3 removes the directory; all other command tests pass.

---

### Task 3: Rehome Non-Information Tools and Remove `bin/system`

**Files:**

- Replace: `bin/system/{brew_bundle_dump,system_dump}` → `env_setup dump mac|vscode|antigravity`
- Replace: `bin/system/checkdisk` → `env_setup system disk verify <volume-path>`
- Move: `bin/system/list_big_files.sh` → `bin/disk/list_big_files.sh`
- Move: `bin/system/uninstall_codex.sh` → `bin/codex/uninstall.sh`
- Move: `bin/system/config/pf.conf` → `pkg/sysctl/pf.conf`
- Delete: `bin/system/{README.md,system_info,os_info,cpu_info,mem_info,gpu_info,disk_info,usb_info,display_info,myip,input_info,audio_info}`
- Delete: `bin/system_info`
- Delete: `bin/{brew_bundle_dump,system_dump,vscode_extension_dump,agy-ide_extension_dump}` shell entrypoints
- Retarget: `bin/list_big_files.sh`
- Modify: `bin/network/scan_network.sh`

**Interfaces:**

- `env_setup system show` replaces `system_info`.
- Existing non-information root symlinks keep their names except `checkdisk`, which is replaced by the Cobra command without a compatibility wrapper.
- `scan_network.sh` exposes only its working `private` and `target` modes; stale topology modes that called an already deleted adapter are removed.

- [x] **Step 1: Move each retained tool**

Create the destination domain directories and replace package/IDE shell dump orchestration with:

```text
env_setup dump mac
env_setup dump vscode
env_setup dump antigravity
```

- [x] **Step 2: Remove replaced adapters and stale symlink**

Delete only the listed information scripts, `bin/system/README.md`, `bin/system_info`, then remove the empty `bin/system/` directory.

- [x] **Step 3: Retarget existing symlinks**

Set the existing symlink targets to:

```text
list_big_files.sh  -> disk/list_big_files.sh
```

- [x] **Step 4: Close the stale network reference**

Remove `REPO_BIN_SYSTEM` and the already nonfunctional `topology` / `topology-no-scan` dispatcher branches so no active script points at `bin/system`.

- [x] **Step 5: Verify the directory contract**

Run:

```bash
test ! -e bin/system
go test -count=1 ./cmd/...
```

Expected: both commands exit 0.

---

### Task 4: Canonical Documentation and Full Verification

**Files:**

- Modify: `README.md`
- Modify: `CLAUDE.md`
- Modify: `README.business.md`
- Modify: `README.todo`
- Modify: `bin/README.md`
- Modify: `docs/bin_index.md`
- Modify: `docs/terminology.md`
- Modify: `plans/2026-07-30-system-info-cobra-commands.md`

- [x] **Step 1: Update current documentation owners**

State that `svc/system` directly owns platform probes, remove live `bin/system` paths, document the four relocated tool domains, and mark the earlier adapter-preservation decision superseded by this plan.

- [x] **Step 2: Check active references**

Run:

```bash
rg -n "bin/system|system_info" README.md CLAUDE.md README.business.md README.todo bin/README.md docs/bin_index.md docs/terminology.md cmd svc bin --glob '!bin/system/**'
```

Expected: no active runtime dependency or current instruction points to `bin/system`; historical specs/plans may retain history.

- [x] **Step 3: Run complete verification**

Run:

```bash
gofmt -w cmd svc
go mod tidy
git diff --check
go test -count=1 ./...
go test -race -count=1 ./...
go vet ./...
golangci-lint run --no-config ./...
go build ./...
./build.sh
env_setup system show
```

Expected: all commands exit 0 and the installed binary prints all 10 information sections without `bin/system/`.
