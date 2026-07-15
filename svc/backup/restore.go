package backup

import (
	"bufio"
	"bytes"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

// ImportOptions 控制 Import 的互動行為。
type ImportOptions struct {
	YesAll bool // 全部同意,不逐一詢問 (-y)
	NoDiff bool // 詢問時不顯示 diff (--no-diff)
}

// Import 逐一 (one-by-one) 以明確提示覆寫本機設定。
//
// 預設行為:對每個有 backup 的網域,顯示 current vs backup 的 diff,再詢問 y/N。
// in 為使用者輸入來源 (通常是 os.Stdin),w 為輸出。
func Import(in io.Reader, w io.Writer, opts ImportOptions) error {
	domains, err := LoadManifest()
	if err != nil {
		return err
	}

	dir := BackupDir()
	if _, err := os.Stat(dir); err != nil {
		return fmt.Errorf("backup 目錄不存在,請先執行 `macbackup backup`:%s", dir)
	}

	fmt.Fprintf(w, "匯入 (override) macOS 設定 <- %s\n", dir)
	if opts.YesAll {
		fmt.Fprintln(w, "模式:-y 全部同意")
	}
	fmt.Fprintln(w)

	reader := bufio.NewReader(in)
	var applied, skipped int

	for _, d := range domains {
		file := backupFile(d.Domain)
		if _, err := os.Stat(file); err != nil {
			continue // 此網域沒有 backup,略過
		}

		fmt.Fprintf(w, "──────── %s ────────\n", d.Domain)
		if d.Note != "" {
			fmt.Fprintf(w, "  %s\n", d.Note)
		}

		changed, summary := domainDiff(w, d.Domain, file, opts.NoDiff || opts.YesAll)
		fmt.Fprintf(w, "  %s\n", summary)
		if !changed {
			fmt.Fprintln(w, "  → 內容相同,略過。")
			skipped++
			fmt.Fprintln(w)
			continue
		}

		if !opts.YesAll && !confirm(reader, w, d.Domain) {
			fmt.Fprintln(w, "  → 略過。")
			skipped++
			fmt.Fprintln(w)
			continue
		}

		if err := importDomain(d.Domain, file); err != nil {
			fmt.Fprintf(w, "  ✗ 覆寫失敗:%v\n\n", err)
			continue
		}
		fmt.Fprintf(w, "  ✓ 已覆寫 %s\n\n", d.Domain)
		applied++
	}

	fmt.Fprintf(w, "完成:覆寫 %d 個,略過 %d 個。\n", applied, skipped)
	if applied > 0 {
		fmt.Fprintln(w, "提示:部分設定需登出 / 重啟對應 App (Dock、Finder) 才會生效。")
	}
	return nil
}

// domainDiff 比較本機現值與 backup 檔;回傳是否有差異,以及要印給使用者看的摘要。
// quiet 為 true 時不印出逐行 diff,只回報是否有差異。
func domainDiff(w io.Writer, domain, file string, quiet bool) (changed bool, summary string) {
	current, live, err := exportDomainXML(domain)
	if err != nil {
		return true, fmt.Sprintf("(無法讀取現值:%v — 視為需覆寫)", err)
	}
	backup, err := normalizeXMLFile(file)
	if err != nil {
		return true, fmt.Sprintf("(無法讀取 backup:%v)", err)
	}

	if !live {
		if !quiet {
			printDiff(w, "", string(backup))
		}
		return true, "本機尚無此網域 → 將以 backup 建立。"
	}

	if bytes.Equal(bytes.TrimSpace(current), bytes.TrimSpace(backup)) {
		return false, "current == backup"
	}

	if !quiet {
		printDiff(w, string(current), string(backup))
	}
	return true, "current ≠ backup → 將以 backup 覆寫本機現值。"
}

// printDiff 以 `diff -u` 顯示 current(現值) vs backup 的差異。
func printDiff(w io.Writer, current, backup string) {
	tmp, err := os.MkdirTemp("", "macbackup-diff-")
	if err != nil {
		return
	}
	defer os.RemoveAll(tmp)

	curPath := filepath.Join(tmp, "current")
	bakPath := filepath.Join(tmp, "backup")
	if err := os.WriteFile(curPath, []byte(current), 0o600); err != nil {
		return
	}
	if err := os.WriteFile(bakPath, []byte(backup), 0o600); err != nil {
		return
	}

	// diff 有差異時 exit code 1,屬正常,不當錯誤。
	out, _ := exec.Command("diff", "-u",
		"--label", "current(本機現值)", curPath,
		"--label", "backup(將覆寫成)", bakPath,
	).Output()
	for line := range strings.SplitSeq(strings.TrimRight(string(out), "\n"), "\n") {
		fmt.Fprintf(w, "  │ %s\n", line)
	}
}

// confirm 逐一詢問是否覆寫某網域,預設為 No。
func confirm(reader *bufio.Reader, w io.Writer, domain string) bool {
	fmt.Fprintf(w, "  覆寫 %s? [y/N] ", domain)
	line, err := reader.ReadString('\n')
	if err != nil {
		return false
	}
	switch strings.ToLower(strings.TrimSpace(line)) {
	case "y", "yes":
		return true
	default:
		return false
	}
}
