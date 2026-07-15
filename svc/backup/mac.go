package backup

// mac.go — 與 macOS 的互動封裝 (how to interact with mac):
// 透過 `defaults` 讀寫設定網域,並以 `plutil` 正規化 plist 供 diff 使用。

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
)

// domainExists 回報本機是否存在該 `defaults` 網域。
func domainExists(domain string) bool {
	return exec.Command("defaults", "read", domain).Run() == nil
}

// exportDomain 把網域完整匯出成 XML plist 檔 (`defaults export <domain> <path>`)。
func exportDomain(domain, path string) error {
	cmd := exec.Command("defaults", "export", domain, path)
	if out, err := cmd.CombinedOutput(); err != nil {
		return fmt.Errorf("defaults export %s: %w: %s", domain, err, bytes.TrimSpace(out))
	}
	return nil
}

// exportDomainXML 把網域匯出為正規化 XML bytes,供 diff 用;網域不存在時回傳 (nil,false,nil)。
func exportDomainXML(domain string) ([]byte, bool, error) {
	if !domainExists(domain) {
		return nil, false, nil
	}
	// defaults export - 送到 stdout;再以 plutil 轉為穩定的 xml1 格式。
	raw, err := exec.Command("defaults", "export", domain, "-").Output()
	if err != nil {
		return nil, true, fmt.Errorf("defaults export %s -: %w", domain, err)
	}
	xml, err := plutilXML(raw)
	if err != nil {
		return raw, true, nil // plutil 失敗時退回原始輸出,仍可粗略 diff
	}
	return xml, true, nil
}

// importDomain 以 backup 檔覆寫 (override) 整個網域 (`defaults import <domain> <path>`)。
func importDomain(domain, path string) error {
	cmd := exec.Command("defaults", "import", domain, path)
	if out, err := cmd.CombinedOutput(); err != nil {
		return fmt.Errorf("defaults import %s: %w: %s", domain, err, bytes.TrimSpace(out))
	}
	return nil
}

// normalizeXMLFile 讀取 backup 檔並轉為穩定 xml1 格式,供 diff 用。
func normalizeXMLFile(path string) ([]byte, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	xml, err := plutilXML(data)
	if err != nil {
		return data, nil // 退回原始內容
	}
	return xml, nil
}

// plutilXML 以 plutil 把 plist bytes 轉為穩定的 xml1 格式。
func plutilXML(in []byte) ([]byte, error) {
	cmd := exec.Command("plutil", "-convert", "xml1", "-o", "-", "-")
	cmd.Stdin = bytes.NewReader(in)
	return cmd.Output()
}
