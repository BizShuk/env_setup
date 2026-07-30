package dump

import (
	"context"
	"errors"
	"fmt"
	"io"
	"path/filepath"
)

// DumpMac writes the current Homebrew bundle to scripts/Brewfile.
func (s *Service) DumpMac(ctx context.Context, out, errOut io.Writer) error {
	if s.goos != "darwin" {
		return errors.New("mac manifest dump requires macOS")
	}
	if err := s.validateRepository(); err != nil {
		return err
	}
	if err := s.requireCommand("brew"); err != nil {
		return err
	}

	path := filepath.Join(s.repositoryDir, "scripts", "Brewfile")
	if err := s.runner.Run(
		ctx,
		nil,
		out,
		errOut,
		"brew",
		"bundle",
		"dump",
		"--force",
		"--file="+path,
	); err != nil {
		return fmt.Errorf("run brew bundle dump: %w", err)
	}
	if _, err := fmt.Fprintf(out, "Mac manifest dumped to %s\n", path); err != nil {
		return fmt.Errorf("write mac dump result: %w", err)
	}
	return nil
}
