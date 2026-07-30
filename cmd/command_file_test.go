package cmd

import (
	"go/ast"
	"go/parser"
	"go/token"
	"io/fs"
	"os"
	"path/filepath"
	"reflect"
	"strconv"
	"strings"
	"testing"
)

func TestSystemCommandHasNoBinSystemRuntimeDependency(t *testing.T) {
	_, err := os.Stat(filepath.Join("..", "bin", "system"))
	if err == nil {
		t.Fatal("bin/system still exists; env_setup system must own native probes")
	}
	if !os.IsNotExist(err) {
		t.Fatalf("stat bin/system: %v", err)
	}
}

func TestNetworkCommandHasNoBinNetworkRuntimeDependency(t *testing.T) {
	_, err := os.Stat(filepath.Join("..", "bin", "network"))
	if err == nil {
		t.Fatal("bin/network still exists; env_setup network must own native scans")
	}
	if !os.IsNotExist(err) {
		t.Fatalf("stat bin/network: %v", err)
	}
}

func TestSystemDiskVerifyHasNoBinCheckdiskRuntimeDependency(t *testing.T) {
	for _, path := range []string{
		filepath.Join("..", "bin", "checkdisk"),
		filepath.Join("..", "bin", "disk", "checkdisk"),
	} {
		_, err := os.Lstat(path)
		if err == nil {
			t.Errorf("%s still exists; env_setup system disk verify must own F3 verification", path)
			continue
		}
		if !os.IsNotExist(err) {
			t.Errorf("stat %s: %v", path, err)
		}
	}
}

func TestDumpCommandHasNoShellRuntimeDependency(t *testing.T) {
	for _, path := range []string{
		filepath.Join("..", "bin", "system_dump"),
		filepath.Join("..", "bin", "brew_bundle_dump"),
		filepath.Join("..", "bin", "vscode_extension_dump"),
		filepath.Join("..", "bin", "agy-ide_extension_dump"),
		filepath.Join("..", "bin", "package", "system_dump"),
		filepath.Join("..", "bin", "package", "brew_bundle_dump"),
		filepath.Join("..", "bin", "vscode", "vscode_extension_dump"),
		filepath.Join("..", "bin", "vscode", "agy-ide_extension_dump"),
	} {
		_, err := os.Lstat(path)
		if err == nil {
			t.Errorf("%s still exists; env_setup dump must own manifest exports", path)
			continue
		}
		if !os.IsNotExist(err) {
			t.Errorf("stat %s: %v", path, err)
		}
	}
}

func TestInstallCommandHasNoShellRuntimeDependency(t *testing.T) {
	for _, path := range []string{
		filepath.Join("..", "bin", "agy-ide_extension_install"),
		filepath.Join("..", "bin", "vscode", "agy-ide_extension_install"),
	} {
		_, err := os.Lstat(path)
		if err == nil {
			t.Errorf("%s still exists; env_setup install must own extension restoration", path)
			continue
		}
		if !os.IsNotExist(err) {
			t.Errorf("stat %s: %v", path, err)
		}
	}
}

func TestUninstallCommandHasNoShellRuntimeDependency(t *testing.T) {
	path := filepath.Join("..", "bin", "codex", "uninstall.sh")
	_, err := os.Lstat(path)
	if err == nil {
		t.Errorf("%s still exists; env_setup uninstall must own Codex removal", path)
		return
	}
	if !os.IsNotExist(err) {
		t.Errorf("stat %s: %v", path, err)
	}
}

func TestCobraCommandsUseOnePackageRelativeNamedFileEach(t *testing.T) {
	want := map[string][]string{
		"root.go":                          {"env_setup"},
		"backup/backup.go":                 {"backup"},
		"backup/import.go":                 {"import"},
		"backup/init.go":                   {"init"},
		"backup/list.go":                   {"list"},
		"cleanup/cleanup.go":               {"cleanup"},
		"dump/antigravity-extension.go":    {"antigravity-extension"},
		"dump/dump.go":                     {"dump"},
		"dump/mac.go":                      {"mac"},
		"dump/vscode-extension.go":         {"vscode-extension"},
		"install/antigravity-extension.go": {"antigravity-extension"},
		"install/install.go":               {"install"},
		"network/network.go":               {"network"},
		"network/private.go":               {"private"},
		"network/target.go":                {"target"},
		"system/system.go":                 {"system"},
		"system/audio.go":                  {"audio"},
		"system/audioShow.go":              {"show"},
		"system/cpu.go":                    {"cpu"},
		"system/cpuShow.go":                {"show"},
		"system/disk.go":                   {"disk"},
		"system/diskShow.go":               {"show"},
		"system/diskVerify.go":             {"verify"},
		"system/display.go":                {"display"},
		"system/displayShow.go":            {"show"},
		"system/gpu.go":                    {"gpu"},
		"system/gpuShow.go":                {"show"},
		"system/input.go":                  {"input"},
		"system/inputShow.go":              {"show"},
		"system/memory.go":                 {"memory"},
		"system/memoryShow.go":             {"show"},
		"system/network.go":                {"network"},
		"system/networkShow.go":            {"show"},
		"system/os.go":                     {"os"},
		"system/osShow.go":                 {"show"},
		"system/show.go":                   {"show"},
		"system/usb.go":                    {"usb"},
		"system/usbShow.go":                {"show"},
		"uninstall/codex.go":               {"codex"},
		"uninstall/uninstall.go":           {"uninstall"},
	}

	got := cobraCommandUsesByFile(t, ".")
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("Cobra command files = %#v, want %#v", got, want)
	}
}

func cobraCommandUsesByFile(t *testing.T, root string) map[string][]string {
	t.Helper()

	commands := make(map[string][]string)
	err := filepath.WalkDir(root, func(path string, entry fs.DirEntry, walkErr error) error {
		if walkErr != nil {
			return walkErr
		}
		if entry.IsDir() || filepath.Ext(path) != ".go" || strings.HasSuffix(path, "_test.go") {
			return nil
		}

		file, err := parser.ParseFile(token.NewFileSet(), path, nil, 0)
		if err != nil {
			return err
		}
		ast.Inspect(file, func(node ast.Node) bool {
			literal, ok := node.(*ast.CompositeLit)
			if !ok || !isCobraCommandType(literal.Type) {
				return true
			}
			if use, ok := cobraCommandUse(literal); ok {
				relativePath, err := filepath.Rel(root, path)
				if err != nil {
					t.Errorf("resolve relative path for %s: %v", path, err)
					return false
				}
				relativePath = filepath.ToSlash(relativePath)
				commands[relativePath] = append(commands[relativePath], use)
			}
			return true
		})
		return nil
	})
	if err != nil {
		t.Fatalf("inspect Cobra command files: %v", err)
	}
	return commands
}

func isCobraCommandType(expression ast.Expr) bool {
	selector, ok := expression.(*ast.SelectorExpr)
	if !ok || selector.Sel.Name != "Command" {
		return false
	}
	identifier, ok := selector.X.(*ast.Ident)
	return ok && identifier.Name == "cobra"
}

func cobraCommandUse(literal *ast.CompositeLit) (string, bool) {
	for _, element := range literal.Elts {
		field, ok := element.(*ast.KeyValueExpr)
		if !ok {
			continue
		}
		key, ok := field.Key.(*ast.Ident)
		if !ok || key.Name != "Use" {
			continue
		}
		value, ok := field.Value.(*ast.BasicLit)
		if !ok || value.Kind != token.STRING {
			return "", false
		}
		use, err := strconv.Unquote(value.Value)
		if err != nil {
			return "", false
		}
		fields := strings.Fields(use)
		if len(fields) == 0 {
			return "", false
		}
		return fields[0], true
	}
	return "", false
}
