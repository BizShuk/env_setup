package dump

import (
	"context"
	"io"
)

// DumpVSCode writes installed VS Code extensions to the tracked manifest.
func (s *Service) DumpVSCode(ctx context.Context, out, errOut io.Writer) error {
	return s.dumpExtensions(
		ctx,
		"code",
		"vscode_extension_list.txt",
		out,
		errOut,
	)
}
