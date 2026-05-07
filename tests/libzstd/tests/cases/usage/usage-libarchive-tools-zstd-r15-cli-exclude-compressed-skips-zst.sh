#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r15-cli-exclude-compressed-skips-zst
# @title: zstd -r --exclude-compressed leaves pre-existing .zst inputs untouched while compressing the rest
# @description: Stages a directory containing both raw text files and an already-compressed .zst, runs zstd -r --exclude-compressed against the directory, and asserts the previously-compressed file is not re-compressed (no .zst.zst is produced) while the raw inputs gain .zst siblings.
# @timeout: 60
# @tags: usage, archive, zstd, cli, exclude-compressed
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

work="$tmpdir/work"
mkdir -p "$work"
printf 'r15 raw alpha\n' >"$work/a.txt"
printf 'r15 raw bravo\n' >"$work/b.txt"

# Pre-existing .zst that must NOT be re-compressed.
zstd -q -o "$work/already.bin.zst" "$work/a.txt"

zstd -q -r --exclude-compressed "$work"

validator_require_file "$work/a.txt.zst"
validator_require_file "$work/b.txt.zst"
validator_require_file "$work/already.bin.zst"

# The pre-existing .zst must not have been wrapped into a .zst.zst.
[[ ! -e "$work/already.bin.zst.zst" ]] || {
    printf 'unexpected double-compressed file: already.bin.zst.zst\n' >&2
    ls -la "$work" >&2
    exit 1
}
