#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch17-xz-check-sha256
# @title: xz --check=sha256 integrity check
# @description: Compresses a payload with xz --check=sha256, confirms xz --list reports the SHA-256 integrity check, and verifies bsdtar can decompress and round-trip the contents.
# @timeout: 180
# @tags: usage, archive, xz, cli, integrity
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src" "$tmpdir/out"
printf 'sha256 check payload\nrow two\nrow three\n' >"$tmpdir/src/data.txt"
src_sha=$(sha256sum "$tmpdir/src/data.txt" | awk '{print $1}')

bsdtar -cf "$tmpdir/plain.tar" -C "$tmpdir/src" data.txt
xz --check=sha256 -z -c "$tmpdir/plain.tar" >"$tmpdir/plain.tar.xz"

# .xz magic
magic_hex=$(head -c 6 "$tmpdir/plain.tar.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

# xz --list verbose must report the SHA-256 check.
xz --list -vv "$tmpdir/plain.tar.xz" >"$tmpdir/list.txt" 2>&1
validator_assert_contains "$tmpdir/list.txt" 'SHA-256'

# Decompress via bsdtar and confirm content survives.
bsdtar -xf "$tmpdir/plain.tar.xz" -C "$tmpdir/out"
out_sha=$(sha256sum "$tmpdir/out/data.txt" | awk '{print $1}')
[[ "$src_sha" == "$out_sha" ]] || {
  printf 'sha mismatch: %s vs %s\n' "$src_sha" "$out_sha" >&2
  exit 1
}
