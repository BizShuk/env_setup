package dump

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"sort"
	"strings"
)

func (s *Service) dumpExtensions(
	ctx context.Context,
	commandName string,
	manifestName string,
	out io.Writer,
	errOut io.Writer,
	extraArgs ...string,
) error {
	if err := s.validateRepository(); err != nil {
		return err
	}
	if err := s.requireCommand(commandName); err != nil {
		return err
	}

	var commandOutput bytes.Buffer
	if err := s.runner.Run(
		ctx,
		nil,
		&commandOutput,
		errOut,
		commandName,
		append(extraArgs, "--list-extensions")...,
	); err != nil {
		return fmt.Errorf("run %s --list-extensions: %w", commandName, err)
	}

	path := filepath.Join(s.repositoryDir, "bin", "vscode", manifestName)
	count, writeErr := writeExtensionManifest(path, commandOutput.String())
	if writeErr != nil {
		return fmt.Errorf("write %s manifest: %w", commandName, writeErr)
	}
	if _, outputErr := fmt.Fprintf(out, "%d extensions dumped to %s\n", count, path); outputErr != nil {
		return fmt.Errorf("write %s dump result: %w", commandName, outputErr)
	}
	return nil
}

func writeExtensionManifest(path string, raw string) (int, error) {
	unique := make(map[string]struct{})
	for line := range strings.SplitSeq(raw, "\n") {
		extension := strings.TrimSpace(line)
		if extension != "" {
			unique[extension] = struct{}{}
		}
	}
	extensions := make([]string, 0, len(unique))
	for extension := range unique {
		extensions = append(extensions, extension)
	}
	sort.Strings(extensions)

	content := ""
	if len(extensions) > 0 {
		content = strings.Join(extensions, "\n") + "\n"
	}
	if err := atomicWriteFile(path, []byte(content)); err != nil {
		return 0, err
	}
	return len(extensions), nil
}

func atomicWriteFile(path string, content []byte) error {
	directory := filepath.Dir(path)
	if _, err := os.Stat(directory); err != nil {
		return fmt.Errorf("stat output directory %s: %w", directory, err)
	}
	file, createErr := os.CreateTemp(directory, ".extension-manifest-*")
	if createErr != nil {
		return fmt.Errorf("create temporary manifest: %w", createErr)
	}
	tempPath := file.Name()
	defer os.Remove(tempPath)

	if _, writeErr := file.Write(content); writeErr != nil {
		return closeManifestAfterError(file, fmt.Errorf("write temporary manifest: %w", writeErr))
	}
	if chmodErr := file.Chmod(0o644); chmodErr != nil {
		return closeManifestAfterError(file, fmt.Errorf("chmod temporary manifest: %w", chmodErr))
	}
	if closeErr := file.Close(); closeErr != nil {
		return fmt.Errorf("close temporary manifest: %w", closeErr)
	}
	if renameErr := os.Rename(tempPath, path); renameErr != nil {
		return fmt.Errorf("replace manifest: %w", renameErr)
	}
	return nil
}

func closeManifestAfterError(file *os.File, operationErr error) error {
	if closeErr := file.Close(); closeErr != nil {
		return errors.Join(operationErr, fmt.Errorf("close temporary manifest: %w", closeErr))
	}
	return operationErr
}
