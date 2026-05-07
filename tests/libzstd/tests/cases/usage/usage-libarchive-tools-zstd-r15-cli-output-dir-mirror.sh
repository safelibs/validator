#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r15-cli-output-dir-mirror
# @title: zstd --output-dir-mirror reproduces the source directory tree under the mirror root
# @description: Compresses a nested input tree with zstd -r --output-dir-mirror and asserts the mirror root contains the same relative directory layout, with each input file replaced by an .zst sibling at the mirrored path. The original tree must not gain new .zst entries.
# @timeout: 60
# @tags: usage, archive, zstd, cli, output-dir-mirror
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src/sub/leaf"
printf 'r15 mirror file a\n' >"$tmpdir/src/a.txt"
printf 'r15 mirror file b\n' >"$tmpdir/src/sub/b.txt"
printf 'r15 mirror file c\n' >"$tmpdir/src/sub/leaf/c.txt"

# Run zstd from $tmpdir using a relative input path so --output-dir-mirror
# replicates a relative tree under "mirror/" rather than mirroring an
# absolute path layout.
( cd "$tmpdir" && zstd -q -r --output-dir-mirror mirror src )

validator_require_file "$tmpdir/mirror/src/a.txt.zst"
validator_require_file "$tmpdir/mirror/src/sub/b.txt.zst"
validator_require_file "$tmpdir/mirror/src/sub/leaf/c.txt.zst"

# Source tree must remain pristine.
[[ ! -e "$tmpdir/src/a.txt.zst" ]]
[[ ! -e "$tmpdir/src/sub/b.txt.zst" ]]
[[ ! -e "$tmpdir/src/sub/leaf/c.txt.zst" ]]

# Each mirrored .zst must decode back to the source bytes.
zstd -dq -c "$tmpdir/mirror/src/sub/leaf/c.txt.zst" >"$tmpdir/c.decoded"
diff -q "$tmpdir/src/sub/leaf/c.txt" "$tmpdir/c.decoded"
