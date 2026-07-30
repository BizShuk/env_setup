package backup

import (
	"io"

	svc "github.com/bizshuk/env_setup/svc/backup"
	"github.com/spf13/cobra"
)

func newImportCommand(in io.Reader, out io.Writer) *cobra.Command {
	var yesAll bool
	var noDiff bool
	command := &cobra.Command{
		Use:   "import",
		Short: "逐一確認並匯入已備份的 defaults domains",
		Args:  cobra.NoArgs,
		RunE: func(_ *cobra.Command, _ []string) error {
			return svc.Import(in, out, svc.ImportOptions{
				YesAll: yesAll,
				NoDiff: noDiff,
			})
		},
	}
	command.Flags().BoolVarP(&yesAll, "yes", "y", false, "全部同意，不逐一詢問")
	command.Flags().BoolVar(&noDiff, "no-diff", false, "不顯示 current 與 backup diff")
	return command
}
