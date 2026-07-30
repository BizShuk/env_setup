# macOS Cleanup Cobra Command Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 將三個 `mac_cleanup*.sh` 的有效清理行為合併為 `env_setup cleanup` Cobra subcommand，預設只列出 `size` 與 `description`，只有傳入 `--apply` 才逐項確認並執行。

**Architecture:** `main.go` 只初始化 gosdk config/log 並執行 root command；`cmd/` 擁有 Cobra composition 與互動流程，且每個 command 使用獨立的 command-path named file；`svc/cleanup/` 負責 discovery、size calculation 與已確認 action 的執行；`model/cleanup/` 只保存清理項目的純資料。既有 backup CLI 改為 root 底下的 `backup` subcommand。

**Tech Stack:** Go 1.26.0、`github.com/spf13/cobra`、`github.com/bizshuk/gosdk/config`、`github.com/bizshuk/gosdk/log`、`github.com/bizshuk/gosdk/metric`、Go standard library。

## Global Constraints

- 使用繁體中文搭配 English Terminology。
- `env_setup cleanup` 不得修改檔案；`env_setup cleanup --apply` 才能進入逐項 `[y/N]` confirmation。
- confirmation 必須依 item 一次一題；未明確回答 `y` 或 `yes` 一律 skip。
- list 的每個 item 必須顯示 `ID`、`SIZE`、`DESCRIPTION`；無法可靠量測的 command action 顯示 `N/A`。
- deletion 必須使用 discovery 時取得的 exact paths，不在 apply 時重新擴大 glob scope。
- Cobra production files 必須維持 one command one file；檔名採 package-relative command path，不重複 package prefix。
- 保留無關修改 `bin/vscode/settings.json`。
- 被取代的三個 scripts 為 `bin/mac/mac_cleanup.sh`、`bin/mac/mac_cleanup_tmp.sh`、`bin/mac/mac_cleanup_tmp_2.sh`。

---

### Task 1: Cleanup Domain and TDD Contract

**Files:**

- Create: `model/cleanup/item.go`
- Create: `svc/cleanup/catalog.go`
- Create: `svc/cleanup/discovery.go`
- Create: `svc/cleanup/service.go`
- Create: `svc/cleanup/discovery_test.go`
- Create: `svc/cleanup/service_test.go`

**Interfaces:**

- Produces:

```go
type Item struct {
	ID          string
	Description string
	SizeBytes   int64
	SizeKnown   bool
	Available   bool
}

type Service struct {
	// private catalog and command runner
}

func New(definitions []Definition, runner Runner) *Service
func NewDefault() (*Service, error)
func (s *Service) Inspect(ctx context.Context) (*Plan, error)
func (p *Plan) Items() []modelcleanup.Item
func (p *Plan) Apply(ctx context.Context, id string) error
```

- `Plan` privately owns the exact discovered targets and commands so `Apply` cannot expand beyond the item the user reviewed.

- [x] **Step 1: Write failing discovery tests**

```go
func TestInspectListsDescriptionAndRecursiveSize(t *testing.T) {
	root := t.TempDir()
	require.NoError(t, os.WriteFile(filepath.Join(root, "cache.bin"), []byte("12345"), 0o600))

	service := New([]Definition{{
		ID:          "cache",
		Description: "清理測試 Cache",
		Selectors:   []Selector{{Kind: SELECTOR_CONTENTS, Path: root}},
	}}, NewCommandRunner())

	plan, err := service.Inspect(context.Background())
	require.NoError(t, err)
	require.Equal(t, int64(5), plan.Items()[0].SizeBytes)
	require.Equal(t, "清理測試 Cache", plan.Items()[0].Description)
}

func TestInspectOlderFilesKeepsRecentFiles(t *testing.T) {
	// 建立 old/recent files，確認 Plan 只捕捉超過 age threshold 的 exact old path。
}
```

- [x] **Step 2: Run tests and verify RED**

Run: `go test ./svc/cleanup`

Expected: FAIL because the `svc/cleanup` implementation does not exist.

- [x] **Step 3: Implement model, selectors, discovery, size calculation, and immutable Plan**

`catalog.go` 必須把三個 shell scripts 的重複行為合併成單一 catalog，涵蓋 system/user caches、Darwin temp caches、Lark、npm/npx/Bun、Go/Python/brew caches、AI generated/temp/session data、Docker、Trash、Time Machine、iOS backup/update、Safari reset、media/chat data、Java、`node_modules` 與非保留 venv directories。高風險項目不得自動執行，只作為獨立 item 等待 confirmation。

- [x] **Step 4: Run discovery tests and verify GREEN**

Run: `go test ./svc/cleanup`

Expected: PASS.

- [x] **Step 5: Write failing apply tests**

```go
func TestPlanApplyDeletesOnlyDiscoveredTargets(t *testing.T) {
	// Inspect 後建立另一個未列入 snapshot 的檔案。
	// Apply 必須刪除 snapshot target，並保留後建立的檔案。
}

func TestPlanApplyRejectsUnknownItem(t *testing.T) {
	err := plan.Apply(context.Background(), "not-reviewed")
	require.ErrorContains(t, err, "unknown cleanup item")
}
```

- [x] **Step 6: Run apply tests and verify RED**

Run: `go test ./svc/cleanup`

Expected: FAIL because `Plan.Apply` does not yet execute the reviewed action.

- [x] **Step 7: Implement safe apply**

Path actions 使用 `os.RemoveAll`；root-owned actions 以 argument array 呼叫 `sudo rm -rf -- <exact paths>`，不得經 shell interpolation；command actions 使用 `exec.CommandContext`。每個 error 以 item/action context 包裝並回傳。

- [x] **Step 8: Run service tests and verify GREEN**

Run: `go test ./svc/cleanup`

Expected: PASS.

### Task 2: Cobra Composition, Backup Subcommand, and Documentation

**Files:**

- Create: `cmd/root.go`
- Create: `cmd/root_test.go`
- Create: `cmd/command_file_test.go`
- Create: `cmd/cleanup/cleanup.go`
- Create: `cmd/cleanup/cleanup_test.go`
- Create: `cmd/backup/backup.go`
- Create: `cmd/backup/import.go`
- Create: `cmd/backup/init.go`
- Create: `cmd/backup/list.go`
- Delete: `cmd/backup/command.go`
- Modify: `main.go`
- Modify: `go.mod`
- Modify: `go.sum`
- Modify: `build.sh`
- Delete: `bin/mac/mac_cleanup.sh`
- Delete: `bin/mac/mac_cleanup_tmp.sh`
- Delete: `bin/mac/mac_cleanup_tmp_2.sh`
- Modify: `README.md`
- Modify: `CLAUDE.md`
- Modify: `README.todo`
- Modify: `docs/bin_index.md`
- Create: `docs/terminology.md`

**Interfaces:**

- Consumes: `cleanup.Service.Inspect`, `Plan.Items`, `Plan.Apply`。
- Produces:

```go
func NewRootCommand(cleanupService *cleanup.Service, in io.Reader, out, errOut io.Writer) *cobra.Command
func Execute(args []string, in io.Reader, out, errOut io.Writer) int
func cleanupcmd.NewCommand(service *cleanup.Service, in io.Reader, out io.Writer) *cobra.Command
func backupcmd.NewCommand(in io.Reader, out io.Writer) *cobra.Command
```

- [x] **Step 1: Write failing command tests**

```go
func TestCleanupPreviewListsItemsWithoutPromptOrApply(t *testing.T) {
	// 執行 cleanup，不帶 --apply；assert headers/size/description，且 target 仍存在。
}

func TestCleanupApplyConfirmsOneByOne(t *testing.T) {
	// 輸入 "y\nn\n"；assert 第一項刪除、第二項保留，且出現兩個 [y/N] prompts。
}

func TestRootContainsCleanupAndBackupSubcommands(t *testing.T) {
	// assert root.Find([]string{"cleanup"}) 與 root.Find([]string{"backup"}) 均成功。
}

func TestCobraCommandsUseOnePackageRelativeNamedFileEach(t *testing.T) {
	// parse production Go files；assert 每個 Cobra command 對應唯一的 package-relative named file。
}
```

- [x] **Step 2: Run command tests and verify RED**

Run: `go test ./cmd/...`

Expected: FAIL because Cobra root/cleanup subcommand and backup Cobra adapter do not exist.

- [x] **Step 3: Implement Cobra commands and gosdk wiring**

Root `Use` 為 `env_setup`，加入 `cleanup` 與 `backup`。`cleanup --apply` 先完整列出 snapshot，再逐項詢問；preview 不讀 stdin。`backup` 本身執行 export，並保留 `backup import`、`backup list`、`backup init`；每個 command 放在獨立的 command-path named file。在 root 註冊 `metric.CobraCMDHook`；`main.go` 使用 `config.Default(config.WithAppName("env_setup"))`，並 import pinned gosdk `log` package 以使用其 package-init logger。

- [x] **Step 4: Run command tests and verify GREEN**

Run: `go test ./cmd/...`

Expected: PASS.

- [x] **Step 5: Replace scripts and update canonical docs**

以 `env_setup cleanup` / `env_setup cleanup --apply` 取代三個 scripts 的引用；`build.sh` 安裝 `~/.local/bin/env_setup`；`CLAUDE.md` 單一擁有 Cobra package tree/ownership，`README.md` 只說明為什麼使用及如何開始；`README.todo` 將 mac setting backup/import item 保持未完成，因本次只做 command composition migration。

- [x] **Step 6: Format and tidy dependencies**

Run: `gofmt -w main.go cmd model svc`

Run: `go mod tidy`

Expected: `github.com/spf13/cobra v1.9.1` 成為 direct dependency，格式化無錯誤。

- [x] **Step 7: Run full verification**

Run: `go test -count=1 ./...`

Run: `go vet ./...`

Run: `go build ./...`

Run: `go run . cleanup`

Expected: tests/vet/build exit 0；smoke command 只列出清理項目，不顯示 confirmation prompt，也不執行 deletion。
