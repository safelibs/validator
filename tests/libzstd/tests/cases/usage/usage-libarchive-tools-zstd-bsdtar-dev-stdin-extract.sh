#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-bsdtar-dev-stdin-extract
# @title: bsdtar zstd extract from /dev/stdin path
# @description: Pipes a zstd-compressed tar into bsdtar with the archive path written explicitly as /dev/stdin (rather than the bare '-' alias) and verifies that the extracted tree round-trips by sha256, exercising libarchive's auto-detection of the zstd filter on a stdin-backed character device.
# @timeout: 180
# @tags: usage, archive, zstd, stdin
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in/sub" "$tmpdir/out"
python3 -c '
import sys
sys.stdout.buffer.write(b"dev-stdin payload alpha\n" * 256)
' >"$tmpdir/in/alpha.bin"
python3 -c '
import sys
sys.stdout.buffer.write(b"dev-stdin payload beta nested\n" * 128)
' >"$tmpdir/in/sub/beta.bin"

alpha_sum=$(sha256sum "$tmpdir/in/alpha.bin" | awk '{print $1}')
beta_sum=$(sha256sum "$tmpdir/in/sub/beta.bin" | awk '{print $1}')

bsdtar --zstd -cf "$tmpdir/a.tar.zst" -C "$tmpdir/in" alpha.bin sub/beta.bin
validator_require_file "$tmpdir/a.tar.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/a.tar.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

# Use explicit /dev/stdin path rather than '-' to ensure libarchive treats the
# stdin character device as a regular auto-detected archive source.
bsdtar -xf /dev/stdin -C "$tmpdir/out" <"$tmpdir/a.tar.zst"

validator_require_file "$tmpdir/out/alpha.bin"
validator_require_file "$tmpdir/out/sub/beta.bin"

dst_alpha=$(sha256sum "$tmpdir/out/alpha.bin" | awk '{print $1}')
dst_beta=$(sha256sum "$tmpdir/out/sub/beta.bin" | awk '{print $1}')
test "$alpha_sum" = "$dst_alpha"
test "$beta_sum" = "$dst_beta"
