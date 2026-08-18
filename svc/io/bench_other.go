//go:build !linux && !darwin

package io

import (
	"errors"
	"os"
)

var errUnsupported = errors.New("I/O benchmark is only implemented for linux and darwin")

func openDirect(string, int) (*os.File, error)     { return nil, errUnsupported }
func openDirectSync(string, int) (*os.File, error) { return nil, errUnsupported }
func syncEachWrite(*os.File) error                 { return errUnsupported }
