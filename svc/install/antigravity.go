package install

import (
	"bufio"
	"bytes"
	"context"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"

	rootsvc "github.com/bizshuk/env_setup/svc"
)

const antigravityManifestName = "agy-ide_extension_list.txt"

// InstallAntigravityExtensions synchronizes Antigravity extensions with the tracked manifest.
func (s *Service) InstallAntigravityExtensions(
	ctx context.Context,
	in io.Reader,
	out io.Writer,
	errOut io.Writer,
) error {
	if err := s.validateRepository(); err != nil {
		return err
	}
	if err := s.requireCommand("agy-ide"); err != nil {
		return err
	}

	manifestPath := filepath.Join(
		s.repositoryDir,
		"bin",
		"vscode",
		antigravityManifestName,
	)
	extensions, err := readExtensionManifest(manifestPath)
	if err != nil {
		return err
	}
	if targetErr := s.writeExtensionsTarget(out); targetErr != nil {
		return targetErr
	}
	rejected, installErr := s.installManifestExtensions(ctx, extensions, out, errOut)
	if installErr != nil {
		return installErr
	}

	unlisted, err := s.unlistedAntigravityExtensions(ctx, extensions, errOut)
	if err != nil {
		return err
	}
	if removeErr := s.removeUnlistedExtensions(ctx, in, out, errOut, unlisted); removeErr != nil {
		return removeErr
	}
	return writeRejectedExtensions(out, rejected)
}

// antigravityArgs prefixes the resolved extensions directory so agy-ide never falls back
// to the desktop directory on a machine that only serves Remote-SSH windows.
func (s *Service) antigravityArgs(args ...string) []string {
	if s.extensionsDir == "" {
		return args
	}
	return append([]string{"--extensions-dir", s.extensionsDir}, args...)
}

func (s *Service) writeExtensionsTarget(out io.Writer) error {
	if s.extensionsDir == "" {
		return nil
	}
	if _, err := fmt.Fprintf(out, "Antigravity extensions directory: %s\n", s.extensionsDir); err != nil {
		return fmt.Errorf("write extensions directory: %w", err)
	}
	return nil
}

// installManifestExtensions installs every manifest entry and returns the ones agy-ide
// rejected, so a single unavailable extension cannot abort the whole sync.
func (s *Service) installManifestExtensions(
	ctx context.Context,
	extensions []string,
	out io.Writer,
	errOut io.Writer,
) ([]string, error) {
	var rejected []string
	for _, extension := range extensions {
		if _, err := fmt.Fprintf(out, "Installing Antigravity extension: %s\n", extension); err != nil {
			return nil, fmt.Errorf("write install progress: %w", err)
		}
		err := s.runner.Run(
			ctx,
			nil,
			out,
			errOut,
			"agy-ide",
			s.antigravityArgs("--install-extension", extension, "--force")...,
		)
		if err == nil {
			continue
		}
		var exitErr *rootsvc.ExitError
		if !errors.As(err, &exitErr) {
			return nil, fmt.Errorf("install Antigravity extension %s: %w", extension, err)
		}
		rejected = append(rejected, extension)
	}
	return rejected, nil
}

func (s *Service) removeUnlistedExtensions(
	ctx context.Context,
	in io.Reader,
	out io.Writer,
	errOut io.Writer,
	unlisted []string,
) error {
	if len(unlisted) == 0 {
		if _, writeErr := fmt.Fprintln(out, "Antigravity extensions already match the manifest."); writeErr != nil {
			return fmt.Errorf("write install result: %w", writeErr)
		}
		return nil
	}

	if unlistedWriteErr := writeUnlistedExtensions(out, unlisted); unlistedWriteErr != nil {
		return unlistedWriteErr
	}
	confirmed, err := confirmUninstall(in, out)
	if err != nil {
		return err
	}
	if !confirmed {
		if _, writeErr := fmt.Fprintln(out, "Skipped removal of unlisted Antigravity extensions."); writeErr != nil {
			return fmt.Errorf("write uninstall result: %w", writeErr)
		}
		return nil
	}

	for _, extension := range unlisted {
		if _, writeErr := fmt.Fprintf(out, "Uninstalling Antigravity extension: %s\n", extension); writeErr != nil {
			return fmt.Errorf("write uninstall progress: %w", writeErr)
		}
		if runErr := s.runner.Run(
			ctx,
			nil,
			out,
			errOut,
			"agy-ide",
			s.antigravityArgs("--uninstall-extension", extension)...,
		); runErr != nil {
			return fmt.Errorf("uninstall Antigravity extension %s: %w", extension, runErr)
		}
	}
	return nil
}

func (s *Service) unlistedAntigravityExtensions(
	ctx context.Context,
	manifest []string,
	errOut io.Writer,
) ([]string, error) {
	var installedOutput bytes.Buffer
	if err := s.runner.Run(
		ctx,
		nil,
		&installedOutput,
		errOut,
		"agy-ide",
		s.antigravityArgs("--list-extensions")...,
	); err != nil {
		return nil, fmt.Errorf("list installed Antigravity extensions: %w", err)
	}

	wanted := make(map[string]struct{}, len(manifest))
	for _, extension := range manifest {
		wanted[extension] = struct{}{}
	}
	var unlisted []string
	for _, extension := range uniqueExtensions(installedOutput.String()) {
		if _, exists := wanted[extension]; !exists {
			unlisted = append(unlisted, extension)
		}
	}
	return unlisted, nil
}

func readExtensionManifest(path string) ([]string, error) {
	content, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("read Antigravity extension manifest %s: %w", path, err)
	}
	extensions := uniqueExtensions(string(content))
	if len(extensions) == 0 {
		return nil, fmt.Errorf("antigravity extension manifest %s contains no extensions", path)
	}
	return extensions, nil
}

func uniqueExtensions(raw string) []string {
	seen := make(map[string]struct{})
	var extensions []string
	for line := range strings.SplitSeq(raw, "\n") {
		extension := strings.TrimSpace(line)
		if extension == "" {
			continue
		}
		if _, exists := seen[extension]; exists {
			continue
		}
		seen[extension] = struct{}{}
		extensions = append(extensions, extension)
	}
	return extensions
}

func writeUnlistedExtensions(out io.Writer, extensions []string) error {
	if _, err := fmt.Fprintln(out, "Installed Antigravity extensions absent from the manifest:"); err != nil {
		return fmt.Errorf("write unlisted extension header: %w", err)
	}
	for _, extension := range extensions {
		if _, err := fmt.Fprintf(out, "- %s\n", extension); err != nil {
			return fmt.Errorf("write unlisted extension: %w", err)
		}
	}
	return nil
}

func writeRejectedExtensions(out io.Writer, rejected []string) error {
	if len(rejected) == 0 {
		return nil
	}
	if _, err := fmt.Fprintln(out, "Antigravity extensions the marketplace rejected:"); err != nil {
		return fmt.Errorf("write rejected extension header: %w", err)
	}
	for _, extension := range rejected {
		if _, err := fmt.Fprintf(out, "- %s\n", extension); err != nil {
			return fmt.Errorf("write rejected extension: %w", err)
		}
	}
	return fmt.Errorf(
		"%d Antigravity extensions failed to install: %s",
		len(rejected),
		strings.Join(rejected, ", "),
	)
}

func confirmUninstall(in io.Reader, out io.Writer) (bool, error) {
	if _, err := fmt.Fprint(out, "Uninstall all extensions listed above? [y/N] "); err != nil {
		return false, fmt.Errorf("write uninstall prompt: %w", err)
	}
	response, err := bufio.NewReader(in).ReadString('\n')
	if err != nil && !errors.Is(err, io.EOF) {
		return false, fmt.Errorf("read uninstall confirmation: %w", err)
	}
	return strings.EqualFold(strings.TrimSpace(response), "y"), nil
}
