// Package cmd 組合 env_setup Cobra root command。
package cmd

import (
	"fmt"
	"io"

	backupcmd "github.com/bizshuk/env_setup/cmd/backup"
	cleanupcmd "github.com/bizshuk/env_setup/cmd/cleanup"
	dumpcmd "github.com/bizshuk/env_setup/cmd/dump"
	installcmd "github.com/bizshuk/env_setup/cmd/install"
	networkcmd "github.com/bizshuk/env_setup/cmd/network"
	systemcmd "github.com/bizshuk/env_setup/cmd/system"
	uninstallcmd "github.com/bizshuk/env_setup/cmd/uninstall"
	cleanupsvc "github.com/bizshuk/env_setup/svc/cleanup"
	dumpsvc "github.com/bizshuk/env_setup/svc/dump"
	installsvc "github.com/bizshuk/env_setup/svc/install"
	networksvc "github.com/bizshuk/env_setup/svc/network"
	systemsvc "github.com/bizshuk/env_setup/svc/system"
	uninstallsvc "github.com/bizshuk/env_setup/svc/uninstall"
	"github.com/bizshuk/gosdk/metric"
	"github.com/spf13/cobra"
)

// NewRootCommand 組合 env_setup 的 domain subcommands。
func NewRootCommand(
	cleanupService *cleanupsvc.Service,
	dumpService *dumpsvc.Service,
	installService *installsvc.Service,
	uninstallService *uninstallsvc.Service,
	systemService *systemsvc.Service,
	networkService *networksvc.Service,
	in io.Reader,
	out io.Writer,
	errOut io.Writer,
) *cobra.Command {
	root := &cobra.Command{
		Use:           "env_setup",
		Short:         "本機環境設定、install、uninstall、dump、system、network、cleanup 與 backup 工具",
		SilenceErrors: true,
		SilenceUsage:  true,
		RunE: func(command *cobra.Command, _ []string) error {
			return command.Help()
		},
	}
	root.SetIn(in)
	root.SetOut(out)
	root.SetErr(errOut)
	root.AddCommand(
		cleanupcmd.NewCommand(cleanupService, in, out),
		backupcmd.NewCommand(in, out),
		dumpcmd.NewCommand(dumpService, out, errOut),
		installcmd.NewCommand(installService, in, out, errOut),
		uninstallcmd.NewCommand(uninstallService, in, out, errOut),
		systemcmd.NewCommand(systemService, out, errOut),
		networkcmd.NewCommand(networkService, out, errOut),
	)
	metric.CobraCMDHook(root)
	return root
}

// Execute 建立 default services、執行 root command 並回傳 process exit code。
func Execute(args []string, in io.Reader, out, errOut io.Writer) int {
	cleanupService, err := cleanupsvc.NewDefault()
	if err != nil {
		fmt.Fprintf(errOut, "error: initialize cleanup service: %v\n", err)
		return 1
	}
	dumpService := dumpsvc.NewDefault()
	installService := installsvc.NewDefault()
	uninstallService, err := uninstallsvc.NewDefault()
	if err != nil {
		fmt.Fprintf(errOut, "error: initialize uninstall service: %v\n", err)
		return 1
	}
	systemService := systemsvc.NewDefault()
	networkService := networksvc.NewDefault()
	root := NewRootCommand(
		cleanupService,
		dumpService,
		installService,
		uninstallService,
		systemService,
		networkService,
		in,
		out,
		errOut,
	)
	root.SetArgs(args)
	if err := root.Execute(); err != nil {
		fmt.Fprintf(errOut, "error: %v\n", err)
		return 1
	}
	return 0
}
