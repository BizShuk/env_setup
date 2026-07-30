package dump

import (
	"context"
	"io"
)

// DumpAntigravity writes installed Antigravity extensions to the tracked manifest.
func (s *Service) DumpAntigravity(ctx context.Context, out, errOut io.Writer) error {
	return s.dumpExtensions(
		ctx,
		"agy-ide",
		"agy-ide_extension_list.txt",
		out,
		errOut,
	)
}
