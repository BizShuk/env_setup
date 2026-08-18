//go:build darwin

package io

import (
	"os"
	"syscall"
)

// openDirect disables the unified buffer cache for this descriptor
// (F_NOCACHE), macOS's equivalent of O_DIRECT.
func openDirect(path string, flag int) (*os.File, error) {
	file, err := os.OpenFile(path, flag, 0o600)
	if err != nil {
		return nil, err
	}
	if _, err := fcntl(file.Fd(), syscall.F_NOCACHE, 1); err != nil {
		file.Close()
		return nil, err
	}
	return file, nil
}

// openDirectSync opens uncached; durability per write comes from
// syncEachWrite because macOS treats O_SYNC/fsync as a drive-cache write only.
func openDirectSync(path string, flag int) (*os.File, error) {
	return openDirect(path, flag)
}

// syncEachWrite issues F_FULLFSYNC, the only macOS call that forces the drive
// to flush its own cache — the same guarantee Linux O_DSYNC gives.
func syncEachWrite(file *os.File) error {
	_, err := fcntl(file.Fd(), syscall.F_FULLFSYNC, 0)
	return err
}

func fcntl(fd uintptr, cmd, arg int) (int, error) {
	value, _, errno := syscall.Syscall(syscall.SYS_FCNTL, fd, uintptr(cmd), uintptr(arg))
	if errno != 0 {
		return 0, errno
	}
	return int(value), nil
}
