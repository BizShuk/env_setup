//go:build linux

package io

import (
	"os"
	"syscall"
)

// openDirect bypasses the page cache; the file system still honours fsync.
func openDirect(path string, flag int) (*os.File, error) {
	return os.OpenFile(path, flag|syscall.O_DIRECT, 0o600)
}

// openDirectSync adds O_DSYNC so every write completes only after the device
// has flushed it — the cost containers, journals and databases actually pay.
func openDirectSync(path string, flag int) (*os.File, error) {
	return os.OpenFile(path, flag|syscall.O_DIRECT|syscall.O_DSYNC, 0o600)
}

// syncEachWrite is a no-op on Linux: O_DSYNC already made the write durable.
func syncEachWrite(*os.File) error {
	return nil
}
