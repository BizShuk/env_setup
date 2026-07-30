package system

import (
	"bufio"
	"fmt"
	"io"
	"strings"

	systemsvc "github.com/bizshuk/env_setup/svc/system"
	"github.com/spf13/cobra"
)

func newDiskVerifyCommand(
	service *systemsvc.Service,
	out io.Writer,
	errOut io.Writer,
) *cobra.Command {
	var yes bool
	command := &cobra.Command{
		Use:   "verify <volume-path>",
		Short: "使用 F3 驗證 removable media 容量與資料完整性",
		Long: `使用 diskutil 顯示指定 macOS volume，再依序執行 f3write 與 f3read。

F3 會寫入 test files 直到目標 volume 的可用空間用盡，再讀回驗證實際容量與
資料完整性。預設要求互動確認；只有已確認目標 path 時才使用 --yes。`,
		Args: cobra.ExactArgs(1),
		RunE: func(command *cobra.Command, args []string) error {
			volumePath := args[0]
			if !yes {
				confirmed, err := confirmDiskVerify(command.InOrStdin(), out, volumePath)
				if err != nil {
					return err
				}
				if !confirmed {
					_, err := fmt.Fprintln(out, "略過 F3 disk verification。")
					return err
				}
			}
			return service.VerifyDisk(command.Context(), volumePath, out, errOut)
		},
	}
	command.Flags().BoolVarP(&yes, "yes", "y", false, "略過確認並立即執行 F3 verification")
	return command
}

func confirmDiskVerify(in io.Reader, out io.Writer, volumePath string) (bool, error) {
	if _, err := fmt.Fprintf(
		out,
		"F3 將寫入 test files 直到 %s 的可用空間用盡，再讀回驗證；繼續？ [y/N] ",
		volumePath,
	); err != nil {
		return false, fmt.Errorf("write disk verification prompt: %w", err)
	}
	answer, err := bufio.NewReader(in).ReadString('\n')
	if err != nil && len(answer) == 0 {
		return false, nil
	}
	switch strings.ToLower(strings.TrimSpace(answer)) {
	case "y", "yes":
		return true, nil
	default:
		return false, nil
	}
}
