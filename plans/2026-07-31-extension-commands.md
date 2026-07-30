# Extension Commands Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `executing-plans` to implement this plan task-by-task. This workspace executes inline because delegation is not enabled for this task.

**Goal:** Replace the Antigravity extension install shell entrypoint with `env_setup install antigravity-extension`, and rename the IDE dump leaves to `dump vscode-extension` and `dump antigravity-extension`.

**Architecture:** `cmd/install/` owns Cobra composition and confirmation I/O; `svc/install/` owns repository validation, manifest parsing, and `agy-ide` execution through the shared `svc.Runner`. Existing dump service methods and manifest formats stay unchanged; only their Cobra leaf names and command filenames change.

**Tech Stack:** Go 1.26, Cobra, `github.com/go-cmd/cmd` through `svc.Runner`, standard-library filesystem and I/O APIs.

## Global Constraints

- Preserve the unrelated deletion of `pkg/linux/rc.local`.
- Use exact command names `vscode-extension` and `antigravity-extension`.
- Keep `scripts/Brewfile`, `vscode_extension_list.txt`, and `agy-ide_extension_list.txt` as canonical manifests.
- Do not execute a live extension install or uninstall during verification.
- Keep one Cobra command per package-relative named file.

---

### Task 1: Rename IDE dump leaves

**Files:**

- Move: `cmd/dump/vscode.go` → `cmd/dump/vscode-extension.go`
- Move: `cmd/dump/antigravity.go` → `cmd/dump/antigravity-extension.go`
- Modify: `cmd/dump/dump.go`
- Test: `cmd/dump/dump_test.go`
- Test: `cmd/command_file_test.go`

**Interfaces:**

- Produces: `env_setup dump vscode-extension`
- Produces: `env_setup dump antigravity-extension`
- Preserves: `(*dump.Service).DumpVSCode` and `(*dump.Service).DumpAntigravity`

- [x] **Step 1: Write failing command-name tests**

  Update the expected dump leaves to:

  ```go
  []string{"mac", "vscode-extension", "antigravity-extension"}
  ```

  Update the command-file contract to:

  ```go
  "dump/vscode-extension.go":     {"vscode-extension"},
  "dump/antigravity-extension.go": {"antigravity-extension"},
  ```

- [x] **Step 2: Verify RED**

  Run:

  ```bash
  go test -count=1 ./cmd/dump ./cmd
  ```

  Expected: failure showing the old `vscode` and `antigravity` leaves or filenames.

- [x] **Step 3: Implement the command rename**

  Rename the two files and set their Cobra `Use` fields to:

  ```go
  Use: "vscode-extension"
  Use: "antigravity-extension"
  ```

- [x] **Step 4: Verify GREEN**

  Run:

  ```bash
  go test -count=1 ./cmd/dump ./cmd
  ```

  Expected: both packages pass.

### Task 2: Add the Go-native Antigravity extension installer

**Files:**

- Create: `svc/install/runner.go`
- Create: `svc/install/service.go`
- Create: `svc/install/antigravity.go`
- Test: `svc/install/service_test.go`

**Interfaces:**

- Produces:

  ```go
  type Options struct {
      RepositoryDir string
      Runner        Runner
      LookPath      func(string) (string, error)
  }

  func New(options Options) *Service
  func NewDefault() *Service
  func (s *Service) InstallAntigravityExtensions(
      ctx context.Context,
      in io.Reader,
      out io.Writer,
      errOut io.Writer,
  ) error
  ```

- [x] **Step 1: Write failing service tests**

  Cover these exact behaviors:

  ```text
  installs every unique non-empty manifest entry with:
    agy-ide --install-extension <id> --force
  lists installed extensions after installation
  leaves unlisted extensions installed when confirmation is not y/Y
  removes unlisted extensions after explicit y/Y confirmation
  rejects a missing agy-ide executable before running commands
  rejects an empty manifest to prevent accidental mass removal
  ```

- [x] **Step 2: Verify RED**

  Run:

  ```bash
  go test -count=1 ./svc/install
  ```

  Expected: compile failure because the install service does not exist.

- [x] **Step 3: Implement the service**

  Define the consumer-owned runner boundary:

  ```go
  type Runner interface {
      Run(context.Context, io.Reader, io.Writer, io.Writer, string, ...string) error
  }
  ```

  Parse `bin/vscode/agy-ide_extension_list.txt`, deduplicate entries while preserving manifest order, run installs with `--force`, compute installed entries absent from the manifest, and require an explicit `y` or `Y` before uninstalling them.

- [x] **Step 4: Verify GREEN**

  Run:

  ```bash
  go test -count=1 ./svc/install
  ```

  Expected: package passes without invoking the live `agy-ide` binary.

### Task 3: Add the install Cobra hierarchy and retire the shell adapter

**Files:**

- Create: `cmd/install/install.go`
- Create: `cmd/install/antigravity-extension.go`
- Test: `cmd/install/install_test.go`
- Modify: `cmd/root.go`
- Modify: `cmd/root_test.go`
- Modify: `cmd/command_file_test.go`
- Delete: `bin/vscode/agy-ide_extension_install`
- Delete: `bin/agy-ide_extension_install`

**Interfaces:**

- Produces: `env_setup install antigravity-extension`
- Consumes: `(*install.Service).InstallAntigravityExtensions`

- [x] **Step 1: Write failing Cobra and ownership tests**

  Assert that root contains `install`, install contains only `antigravity-extension`, and neither legacy shell path exists.

- [x] **Step 2: Verify RED**

  Run:

  ```bash
  go test -count=1 ./cmd/install ./cmd
  ```

  Expected: missing command/package and legacy shell ownership failures.

- [x] **Step 3: Implement Cobra composition**

  Add `install.NewCommand(service, in, out, errOut)`, wire a default install service in `cmd.Execute`, and register `install` in the root command.

- [x] **Step 4: Remove shell ownership**

  Remove the root symlink and `bin/vscode/agy-ide_extension_install` after the Go command covers its behavior.

- [x] **Step 5: Verify GREEN**

  Run:

  ```bash
  go test -count=1 ./cmd/install ./cmd
  ```

  Expected: both packages pass.

### Task 4: Update canonical documentation and verify

**Files:**

- Modify: `README.md`
- Modify: `CLAUDE.md`
- Modify: `docs/terminology.md`
- Modify: `docs/bin_index.md`
- Modify: `bin/vscode/README.md`

- [x] **Step 1: Update current command contracts**

  Document:

  ```text
  env_setup install antigravity-extension
  env_setup dump vscode-extension
  env_setup dump antigravity-extension
  ```

  Remove current-index claims that `agy-ide_extension_install` remains a shell or symlink entrypoint.

- [x] **Step 2: Run complete verification**

  Run:

  ```bash
  gofmt -w cmd/install/*.go svc/install/*.go cmd/dump/*.go cmd/root.go cmd/root_test.go cmd/command_file_test.go svc/ownership_test.go
  go test -count=1 ./...
  go test -race -count=1 ./...
  go vet ./...
  go build ./...
  go mod tidy -diff
  git diff --check
  ```

  Expected: every command exits zero.

- [x] **Step 3: Verify command help without mutating IDE state**

  Run:

  ```bash
  go run . install --help
  go run . install antigravity-extension --help
  go run . dump --help
  ```

  Expected: help exposes only the new extension command names and performs no install, uninstall, or dump operation.
