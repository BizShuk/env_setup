// Package backup 為命令層 (CLI command list):解析子指令與旗標,
// 委派給服務層 svc/backup。由 root main.go 於初始化 gosdk config 後呼叫。
package backup

import (
	"fmt"
	"os"

	svc "github.com/bizshuk/env_setup/svc/backup"
)

// Execute 分派子指令並回傳行程結束碼 (exit code)。
//
//	0  成功
//	1  執行錯誤
//	2  參數 / 用法錯誤
func Execute(args []string) int {
	if len(args) == 0 {
		usage()
		return 2
	}

	var err error
	switch args[0] {
	case "backup":
		err = svc.Backup(os.Stdout)
	case "import":
		err = runImport(args[1:])
	case "list":
		err = svc.List(os.Stdout)
	case "init":
		err = svc.Init(os.Stdout)
	case "-h", "--help", "help":
		usage()
		return 0
	default:
		fmt.Fprintf(os.Stderr, "unknown command: %q\n\n", args[0])
		usage()
		return 2
	}

	if err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		return 1
	}
	return 0
}

// runImport 解析 import 子指令旗標後委派給服務層。
func runImport(args []string) error {
	var opts svc.ImportOptions
	for _, a := range args {
		switch a {
		case "-y", "--yes":
			opts.YesAll = true
		case "--no-diff":
			opts.NoDiff = true
		default:
			return fmt.Errorf("unknown flag: %q", a)
		}
	}
	return svc.Import(os.Stdin, os.Stdout, opts)
}

func usage() {
	fmt.Fprint(os.Stderr, `macbackup — 備份 / 匯入 macOS defaults 設定網域

USAGE:
  macbackup backup              匯出網域清單到 backup 目錄
  macbackup import [-y] [--no-diff]
                                逐一以明確提示覆寫本機設定
  macbackup list                顯示網域清單與 backup 狀態
  macbackup init                種入預設網域清單

IMPORT FLAGS:
  -y            全部同意,不逐一詢問 (all yes)
  --no-diff     不顯示 current vs backup 的 diff

PATHS:
  backup dir:   `+svc.BackupDir()+`
  manifest:     `+svc.ManifestPath()+`
`)
}
