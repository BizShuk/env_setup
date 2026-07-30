# Codex Uninstall Command Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `executing-plans` to implement this plan task-by-task. This workspace executes inline because delegation is disabled for this task.

**Goal:** Replace `bin/codex/uninstall.sh` with a Go-native `env_setup uninstall codex` command that previews exact Codex artifacts by default and only removes individually confirmed items with `--apply`.

**Architecture:** `cmd/uninstall/` owns Cobra flags, preview rendering, and `[y/N]` confirmation I/O. `svc/uninstall/` discovers immutable exact filesystem and launchd targets, owns macOS process execution through the shared `svc.Runner`, and applies only the target IDs captured during inspection. The legacy shell adapter is removed after the new service and command tests cover its behavior.

**Tech Stack:** Go 1.26, Cobra, `github.com/go-cmd/cmd` through `svc.Runner`, and standard-library filesystem APIs.

## Global Constraints

- Preserve every unrelated worktree change, including the pre-existing deletion of `pkg/linux/rc.local`.
- Do not run a live Codex uninstall or any destructive smoke test.
- Keep `--with-codexbar` and `--purge-system`; replace unsafe default deletion / `--dry-run` semantics with default preview plus explicit `--apply`.
- Require one confirmation per available immutable target; default every prompt to No.
- Never expand a glob again during apply.
- Pass external command arguments directly without shell interpolation or `eval`.
- Keep one Cobra command per package-relative named file.

---

### Task 1: Add the immutable Codex uninstall service

**Files:**

- Create: `svc/uninstall/runner.go`
- Create: `svc/uninstall/service.go`
- Create: `svc/uninstall/codex.go`
- Test: `svc/uninstall/service_test.go`
- Modify: `svc/ownership_test.go`

**Interfaces:**

- Produces:

  ```go
  type CodexOptions struct {
      WithCodexBar bool
      PurgeSystem  bool
  }

  func New(options Options) *Service
  func NewDefault() (*Service, error)
  func (s *Service) InspectCodex(context.Context, CodexOptions) (*CodexPlan, error)
  func (p *CodexPlan) Items() []Item
  func (p *CodexPlan) Apply(context.Context, string, io.Writer, io.Writer) error
  ```

- Consumes: the shared `svc.Runner` behind a consumer-owned `uninstall.Runner` interface.

- [x] **Step 1: Write failing service tests**

  Cover these exact behaviors:

  ```text
  rejects non-macOS execution
  discovers fixed paths, glob matches, and launchd labels as exact targets
  includes CodexBar only with --with-codexbar
  includes /Library and /etc targets only with --purge-system
  removes only the inspected filesystem target
  never removes a matching path created after inspection
  executes launchctl bootout without shell interpolation
  executes root-owned removals as sudo rm -rf -- <exact-path>
  attempts osascript quit at most once and treats quit failure as best effort
  ```

- [x] **Step 2: Verify RED**

  Run:

  ```bash
  go test -count=1 ./svc/uninstall
  ```

  Expected: compile failure because the uninstall service does not exist.

- [x] **Step 3: Implement the service**

  Build a catalog from the legacy script's app, CLI, user Library, optional CodexBar, and optional system selectors. Expand globs only during `InspectCodex`; store exact actions by item ID. Parse matching `com.openai.codex` launchd labels from `launchctl list`, use `os.RemoveAll` for non-root paths, and use the injected runner for `osascript`, `launchctl`, and `sudo`.

- [x] **Step 4: Verify GREEN**

  Run:

  ```bash
  go test -count=1 ./svc/uninstall
  ```

  Expected: package passes without touching live Codex state.

---

### Task 2: Add the Cobra hierarchy and retire the shell adapter

**Files:**

- Create: `cmd/uninstall/uninstall.go`
- Create: `cmd/uninstall/codex.go`
- Test: `cmd/uninstall/uninstall_test.go`
- Modify: `cmd/root.go`
- Modify: `cmd/root_test.go`
- Modify: `cmd/command_file_test.go`
- Delete: `bin/codex/uninstall.sh`

**Interfaces:**

- Produces:

  ```text
  env_setup uninstall codex
  env_setup uninstall codex --apply
  env_setup uninstall codex --with-codexbar
  env_setup uninstall codex --purge-system
  ```

- [x] **Step 1: Write failing command and ownership tests**

  Assert that:

  ```text
  root contains uninstall
  uninstall contains only codex
  default execution prints preview and removes nothing
  --apply prompts once per available item and removes only y/yes selections
  the legacy bin/codex/uninstall.sh runtime boundary no longer exists
  command files match uninstall/uninstall.go and uninstall/codex.go
  ```

- [x] **Step 2: Verify RED**

  Run:

  ```bash
  go test -count=1 ./cmd/uninstall ./cmd
  ```

  Expected: missing command/package and legacy shell ownership failures.

- [x] **Step 3: Implement Cobra composition**

  Wire a default uninstall service in `cmd.Execute`, add `uninstall` to the root, and expose `--apply`, `--with-codexbar`, and `--purge-system` on the `codex` leaf.

- [x] **Step 4: Remove shell ownership**

  Delete `bin/codex/uninstall.sh` only after the Go service covers its artifact catalog and execution behavior.

- [x] **Step 5: Verify GREEN**

  Run:

  ```bash
  go test -count=1 ./cmd/uninstall ./cmd
  ```

  Expected: both packages pass.

---

### Task 3: Update canonical documentation and verify

**Files:**

- Modify: `README.md`
- Modify: `CLAUDE.md`
- Modify: `docs/terminology.md`
- Modify: `docs/bin_index.md`
- Modify: `bin/README.md`

- [x] **Step 1: Update current contracts**

  Document `env_setup uninstall codex`, its preview/apply safety contract, optional CodexBar/system scopes, service ownership, and removal of `bin/codex/uninstall.sh`.

- [x] **Step 2: Run complete verification**

  Run:

  ```bash
  gofmt -w cmd/uninstall/*.go svc/uninstall/*.go cmd/root.go cmd/root_test.go cmd/command_file_test.go svc/ownership_test.go
  go test -count=1 ./...
  go test -race -count=1 ./...
  go vet ./...
  go build ./...
  go mod tidy -diff
  git diff --check
  golangci-lint run --no-config ./svc/uninstall ./cmd/uninstall
  golangci-lint run --no-config --new-from-rev=HEAD ./...
  ```

  Expected: every command exits zero.

- [x] **Step 3: Verify command help without mutating Codex state**

  Run:

  ```bash
  go run . uninstall --help
  go run . uninstall codex --help
  ```

  Expected: help exposes the new command and flags without quitting or removing Codex.
