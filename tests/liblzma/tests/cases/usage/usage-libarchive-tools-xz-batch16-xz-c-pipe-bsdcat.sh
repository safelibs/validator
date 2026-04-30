#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch16-xz-c-pipe-bsdcat
# @title: xz -c piped into bsdcat
# @description: Pipes xz -c output directly into bsdcat through a FIFO of bytes and verifies sha256 round-trip equality.
# @timeout: 180
# @tags: usage, xz, bsdcat, pipe
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Build a deterministic mixed payload.
{
  for i in $(seq 1 256); do
    printf 'pipe row %04d alpha beta gamma\n' "$i"
  done
  dd if=/dev/zero bs=256 count=8 status=none
} >"$tmpdir/payload.bin"
src_sha=$(sha256sum "$tmpdir/payload.bin" | awk '{print $1}')

# Pipe xz -c stdout through bsdcat stdin.
xz -c "$tmpdir/payload.bin" | bsdcat >"$tmpdir/out.bin"

cmp "$tmpdir/payload.bin" "$tmpdir/out.bin"
out_sha=$(sha256sum "$tmpdir/out.bin" | awk '{print $1}')
test "$src_sha" = "$out_sha"
