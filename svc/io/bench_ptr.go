package io

import "unsafe"

func uintptrOf(buffer []byte) uintptr {
	return uintptr(unsafe.Pointer(&buffer[0]))
}
