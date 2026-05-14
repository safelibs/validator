#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r17-cli-r-recursive-directory-tree
# @title: zstd -r recursively compresses every file in a directory tree to a .zst sibling
# @description: Lays down a small directory tree with three files in two levels, runs 'zstd -q -r' on the root, and asserts a .zst sibling appears next to each source file and each decompresses back to the original payload.
# @timeout: 120
# @tags: usage, archive, zstd, recursive
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/tree"
mkdir -p "$src/sub"
python3 -c 'import sys
sys.stdout.buffer.write(b"alpha row\n" * 200)' >"$src/a.txt"
python3 -c 'import sys
sys.stdout.buffer.write(b"bravo row\n" * 200)' >"$src/b.txt"
python3 -c 'import sys
sys.stdout.buffer.write(b"charlie row\n" * 200)' >"$src/sub/c.txt"

zstd -q -r "$src"

for f in "$src/a.txt" "$src/b.txt" "$src/sub/c.txt"; do
    [[ -f "$f.zst" ]] || { printf 'missing %s.zst\n' "$f" >&2; exit 1; }
    zstd -dq -c "$f.zst" >"$tmpdir/decoded"
    cmp -s "$f" "$tmpdir/decoded" || { printf 'decode mismatch for %s\n' "$f" >&2; exit 1; }
done
