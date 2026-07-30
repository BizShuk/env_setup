// Command env_setup 提供本機環境 cleanup 與 macOS settings backup。
package main

import (
	"os"

	"github.com/bizshuk/env_setup/cmd"
	"github.com/bizshuk/gosdk/config"
	_ "github.com/bizshuk/gosdk/log"
)

// APP_NAME 是 gosdk config 使用的固定 application name。
const APP_NAME = "env_setup"

func main() {
	config.Default(config.WithAppName(APP_NAME))
	os.Exit(cmd.Execute(os.Args[1:], os.Stdin, os.Stdout, os.Stderr))
}
