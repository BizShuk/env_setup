package io

import (
	"io"

	iosvc "github.com/bizshuk/env_setup/svc/io"
	"github.com/spf13/cobra"
)

func newProbeCommand(service *iosvc.Service, out, errOut io.Writer) *cobra.Command {
	var options iosvc.ProbeOptions
	command := &cobra.Command{
		Use:   "probe",
		Short: "列出每顆實體磁碟的 transport、queue depth、write cache 與 mounts；--bench 加測延遲",
		Long: `以裝置為單位列出每顆實體磁碟：DEV / TRAN / ID / MODEL / SIZE / LINK / DRIVER /
QD / WCACHE / ROTA / MOUNTS。Linux 由 lsblk 與 sysfs 取得，macOS 由 diskutil 取得
（macOS 不對外揭露 queue depth 與 write cache，該欄顯示 -）。

--bench 會在 --dir（預設 home）寫一個暫存檔量三個數字：循序寫入 MB/s、
4 KiB 同步寫入 IOPS（flush 延遲）、4 KiB 隨機讀取 IOPS；全程略過 page cache，
測完自動刪檔。`,
		Args: cobra.NoArgs,
		RunE: func(command *cobra.Command, _ []string) error {
			return service.Probe(command.Context(), options, out, errOut)
		},
	}
	command.Flags().BoolVar(&options.Bench, "bench", false, "在 --dir 實測寫入與讀取延遲")
	command.Flags().StringVar(&options.Dir, "dir", "", "benchmark 暫存檔目錄（預設 home）")
	command.Flags().IntVar(&options.SeqMiB, "seq-mib", iosvc.DEFAULT_SEQ_MIB, "循序寫入樣本大小 (MiB)")
	command.Flags().IntVar(&options.Ops, "ops", iosvc.DEFAULT_OPS, "4 KiB 寫入 / 讀取的操作次數")
	return command
}
