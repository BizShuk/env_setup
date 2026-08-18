package io

import (
	"context"
	"crypto/rand"
	"fmt"
	"io"
	"math/big"
	"os"
	"path/filepath"
	"text/tabwriter"
	"time"
)

const (
	BLOCK_SIZE      = 4096
	SEQ_BLOCK_SIZE  = 1 << 20
	DEFAULT_SEQ_MIB = 256
	DEFAULT_OPS     = 200
)

// Bench measures the three numbers that predict how a device behaves under
// docker/registry/database load: sequential write throughput, synchronous
// 4 KiB write IOPS (flush latency), and random 4 KiB read IOPS. All samples
// bypass the page cache and the scratch file is removed afterwards.
func (s *Service) Bench(ctx context.Context, options ProbeOptions, out io.Writer) error {
	if options.SeqMiB <= 0 {
		options.SeqMiB = DEFAULT_SEQ_MIB
	}
	if options.Ops <= 0 {
		options.Ops = DEFAULT_OPS
	}
	scratch, err := os.CreateTemp(options.Dir, ".io-probe-*")
	if err != nil {
		return fmt.Errorf("create scratch file: %w", err)
	}
	path := scratch.Name()
	scratch.Close()
	defer os.Remove(path)

	fmt.Fprintf(out, "bench in %s\n", filepath.Clean(options.Dir))
	writer := tabwriter.NewWriter(out, 0, 0, 2, ' ', 0)

	seqRate, err := benchSequentialWrite(ctx, path, options.SeqMiB)
	if err != nil {
		return err
	}
	fmt.Fprintf(writer, "seq write\t%.0f MB/s\t(%d MiB, 1 MiB blocks, direct + fsync)\n", seqRate, options.SeqMiB)

	syncIOPS, syncLatency, err := benchSyncWrite(ctx, path, options.Ops)
	if err != nil {
		return err
	}
	fmt.Fprintf(writer, "4k sync wr\t%.0f IOPS\t(%.1f ms/op, direct + sync per write)\n", syncIOPS, syncLatency)

	readIOPS, readLatency, err := benchRandomRead(ctx, path, options.Ops)
	if err != nil {
		return err
	}
	fmt.Fprintf(writer, "4k rand rd\t%.0f IOPS\t(%.1f ms/op, direct)\n", readIOPS, readLatency)
	return writer.Flush()
}

func benchSequentialWrite(ctx context.Context, path string, mib int) (float64, error) {
	file, err := openDirect(path, os.O_WRONLY|os.O_TRUNC)
	if err != nil {
		return 0, fmt.Errorf("open for sequential write: %w", err)
	}
	defer file.Close()
	block := alignedBuffer(SEQ_BLOCK_SIZE)
	started := time.Now()
	for i := 0; i < mib; i++ {
		if err := ctx.Err(); err != nil {
			return 0, err
		}
		if _, err := file.Write(block); err != nil {
			return 0, fmt.Errorf("sequential write: %w", err)
		}
	}
	if err := file.Sync(); err != nil {
		return 0, fmt.Errorf("fsync after sequential write: %w", err)
	}
	elapsed := time.Since(started).Seconds()
	return float64(mib) * SEQ_BLOCK_SIZE / 1e6 / elapsed, nil
}

func benchSyncWrite(ctx context.Context, path string, ops int) (float64, float64, error) {
	file, err := openDirectSync(path, os.O_WRONLY)
	if err != nil {
		return 0, 0, fmt.Errorf("open for sync write: %w", err)
	}
	defer file.Close()
	block := alignedBuffer(BLOCK_SIZE)
	started := time.Now()
	for i := 0; i < ops; i++ {
		if err := ctx.Err(); err != nil {
			return 0, 0, err
		}
		if _, err := file.WriteAt(block, int64(i)*BLOCK_SIZE); err != nil {
			return 0, 0, fmt.Errorf("sync write: %w", err)
		}
		if err := syncEachWrite(file); err != nil {
			return 0, 0, fmt.Errorf("flush after write: %w", err)
		}
	}
	elapsed := time.Since(started)
	return float64(ops) / elapsed.Seconds(), float64(elapsed.Milliseconds()) / float64(ops), nil
}

func benchRandomRead(ctx context.Context, path string, ops int) (float64, float64, error) {
	file, err := openDirect(path, os.O_RDONLY)
	if err != nil {
		return 0, 0, fmt.Errorf("open for random read: %w", err)
	}
	defer file.Close()
	info, err := file.Stat()
	if err != nil {
		return 0, 0, fmt.Errorf("stat scratch file: %w", err)
	}
	blocks := info.Size() / BLOCK_SIZE
	if blocks == 0 {
		return 0, 0, fmt.Errorf("scratch file too small for random read")
	}
	block := alignedBuffer(BLOCK_SIZE)
	started := time.Now()
	for i := 0; i < ops; i++ {
		if err := ctx.Err(); err != nil {
			return 0, 0, err
		}
		index, err := rand.Int(rand.Reader, big.NewInt(blocks))
		if err != nil {
			return 0, 0, fmt.Errorf("pick random block: %w", err)
		}
		if _, err := file.ReadAt(block, index.Int64()*BLOCK_SIZE); err != nil && err != io.EOF {
			return 0, 0, fmt.Errorf("random read: %w", err)
		}
	}
	elapsed := time.Since(started)
	return float64(ops) / elapsed.Seconds(), float64(elapsed.Milliseconds()) / float64(ops), nil
}

// alignedBuffer returns a size-byte slice whose backing array starts on a
// BLOCK_SIZE boundary, which O_DIRECT requires on Linux.
func alignedBuffer(size int) []byte {
	raw := make([]byte, size+BLOCK_SIZE)
	offset := 0
	for (uintptrOf(raw[offset:]) % BLOCK_SIZE) != 0 {
		offset++
	}
	return raw[offset : offset+size]
}
