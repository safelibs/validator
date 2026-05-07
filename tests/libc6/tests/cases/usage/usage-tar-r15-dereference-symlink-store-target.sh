#!/usr/bin/env bash
# @testcase: usage-tar-r15-dereference-symlink-store-target
# @title: tar -h dereferences a symlink and stores the target file's bytes in the archive
# @description: Creates a 32-byte regular file plus a symlink pointing at it, archives the symlink with tar -h (--dereference) under LC_ALL=C, extracts into a fresh directory, and asserts the extracted entry is a regular file whose contents match the source target byte-for-byte (proving -h followed the link rather than archiving a symlink stub).
# @timeout: 60
# @tags: usage, tar, dereference, symlink, r15
# @client: tar

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src"
LC_ALL=C printf '%.0sZ' {1..32} >"$tmpdir/src/target.bin"
ln -s target.bin "$tmpdir/src/link.bin"

[[ -L "$tmpdir/src/link.bin" ]]
[[ "$(wc -c <"$tmpdir/src/target.bin")" -eq 32 ]]

# Archive only the symlink with -h: it must be stored as the dereferenced file.
LC_ALL=C tar -h -C "$tmpdir/src" -cf "$tmpdir/out.tar" link.bin

mkdir -p "$tmpdir/extract"
LC_ALL=C tar -C "$tmpdir/extract" -xf "$tmpdir/out.tar"

# Extracted entry must be a regular file (no longer a symlink).
[[ -f "$tmpdir/extract/link.bin" ]]
[[ ! -L "$tmpdir/extract/link.bin" ]]

cmp "$tmpdir/extract/link.bin" "$tmpdir/src/target.bin"
