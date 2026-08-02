package install

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"path/filepath"
)

// InstallVSCodeExtensions synchronizes VS Code extensions using the agy-ide extension manifest.
func (s *Service) InstallVSCodeExtensions(
	ctx context.Context,
	in io.Reader,
	out io.Writer,
	errOut io.Writer,
) error {
	if err := s.validateRepository(); err != nil {
		return err
	}
	if err := s.requireCommand("code"); err != nil {
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
	if installErr := s.installVSCodeManifestExtensions(ctx, extensions, out, errOut); installErr != nil {
		return installErr
	}

	unlisted, err := s.unlistedVSCodeExtensions(ctx, extensions, errOut)
	if err != nil {
		return err
	}
	return s.removeUnlistedVSCodeExtensions(ctx, in, out, errOut, unlisted)
}

func (s *Service) installVSCodeManifestExtensions(
	ctx context.Context,
	extensions []string,
	out io.Writer,
	errOut io.Writer,
) error {
	for _, extension := range extensions {
		if _, err := fmt.Fprintf(out, "Installing VS Code extension: %s\n", extension); err != nil {
			return fmt.Errorf("write install progress: %w", err)
		}
		if err := s.runner.Run(
			ctx,
			nil,
			out,
			errOut,
			"code",
			"--install-extension",
			extension,
			"--force",
		); err != nil {
			return fmt.Errorf("install VS Code extension %s: %w", extension, err)
		}
	}
	return nil
}

func (s *Service) removeUnlistedVSCodeExtensions(
	ctx context.Context,
	in io.Reader,
	out io.Writer,
	errOut io.Writer,
	unlisted []string,
) error {
	if len(unlisted) == 0 {
		if _, writeErr := fmt.Fprintln(out, "VS Code extensions already match the manifest."); writeErr != nil {
			return fmt.Errorf("write install result: %w", writeErr)
		}
		return nil
	}

	if unlistedWriteErr := writeUnlistedVSCodeExtensions(out, unlisted); unlistedWriteErr != nil {
		return unlistedWriteErr
	}
	confirmed, err := confirmUninstall(in, out)
	if err != nil {
		return err
	}
	if !confirmed {
		if _, writeErr := fmt.Fprintln(out, "Skipped removal of unlisted VS Code extensions."); writeErr != nil {
			return fmt.Errorf("write uninstall result: %w", writeErr)
		}
		return nil
	}

	for _, extension := range unlisted {
		if _, writeErr := fmt.Fprintf(out, "Uninstalling VS Code extension: %s\n", extension); writeErr != nil {
			return fmt.Errorf("write uninstall progress: %w", writeErr)
		}
		if runErr := s.runner.Run(
			ctx,
			nil,
			out,
			errOut,
			"code",
			"--uninstall-extension",
			extension,
		); runErr != nil {
			return fmt.Errorf("uninstall VS Code extension %s: %w", extension, runErr)
		}
	}
	return nil
}

func (s *Service) unlistedVSCodeExtensions(
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
		"code",
		"--list-extensions",
	); err != nil {
		return nil, fmt.Errorf("list installed VS Code extensions: %w", err)
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

func writeUnlistedVSCodeExtensions(out io.Writer, extensions []string) error {
	if _, err := fmt.Fprintln(out, "Installed VS Code extensions absent from the manifest:"); err != nil {
		return fmt.Errorf("write unlisted extension header: %w", err)
	}
	for _, extension := range extensions {
		if _, err := fmt.Fprintf(out, "- %s\n", extension); err != nil {
			return fmt.Errorf("write unlisted extension: %w", err)
		}
	}
	return nil
}
