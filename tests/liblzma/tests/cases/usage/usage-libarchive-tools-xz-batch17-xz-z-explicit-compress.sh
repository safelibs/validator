#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch17-xz-z-explicit-compress
# @title: xz -z explicit compress mode
# @description: Drives the xz CLI in explicit compress mode (-z) on a fixture, validates the .xz magic of the output, and confirms bsdtar can read the resulting stream through liblzma.
# @timeout: 180
# @tags: usage, archive, xz, cli
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src" "$tmpdir/out"
printf 'explicit compress payload\nline two\nline three\n' >"$tmpdir/src/payload.txt"
src_sha=$(sha256sum "$tmpdir/src/payload.txt" | awk '{print $1}')

# Wrap in a tar so bsdtar can read it back as an archive.
bsdtar -cf "$tmpdir/plain.tar" -C "$tmpdir/src" payload.txt

# Explicit compress mode (-z). Use -k to keep the input and write to stdout via -c.
xz -z -c "$tmpdir/plain.tar" >"$tmpdir/plain.tar.xz"

# .xz magic
magic_hex=$(head -c 6 "$tmpdir/plain.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

bsdtar -tf "$tmpdir/plain.tar.xz" >"$tmpdir/list"
validator_assert_contains "$tmpdir/list" 'payload.txt'

bsdtar -xf "$tmpdir/plain.tar.xz" -C "$tmpdir/out"
out_sha=$(sha256sum "$tmpdir/out/payload.txt" | awk '{print $1}')
[[ "$src_sha" == "$out_sha" ]] || {
  printf 'sha mismatch: %s vs %s\n' "$src_sha" "$out_sha" >&2
  exit 1
}
