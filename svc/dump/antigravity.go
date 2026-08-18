package dump

import (
	"context"
	"io"
)

// DumpAntigravity writes installed Antigravity extensions to the tracked manifest. The
// resolved extensions directory keeps the dump and the install command on one directory.
func (s *Service) DumpAntigravity(ctx context.Context, out, errOut io.Writer) error {
	var extraArgs []string
	if s.extensionsDir != "" {
		extraArgs = []string{"--extensions-dir", s.extensionsDir}
	}
	return s.dumpExtensions(
		ctx,
		"agy-ide",
		"agy-ide_extension_list.txt",
		out,
		errOut,
		extraArgs...,
	)
}
