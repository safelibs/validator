#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-cli-rm-removes-source
# @title: zstd CLI --rm removes the source after success
# @description: Compresses a payload with the zstd CLI using --rm, verifies the .zst output exists with the zstd magic and round-trips to the original byte stream, and asserts the original source file was removed by the CLI.
# @timeout: 120
# @tags: usage, archive, zstd, cli
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/payload.txt"
printf 'rm-source payload\n' >"$src"
# Capture the expected decoded contents before --rm deletes the source.
expected_sum=$(sha256sum "$src" | awk '{print $1}')
cp "$src" "$tmpdir/expected.txt"

zstd -q --rm "$src"
validator_require_file "$src.zst"
# The original input must be gone.
[[ ! -e "$src" ]] || {
  printf 'expected --rm to delete %s\n' "$src" >&2
  exit 1
}

magic=$(od -An -N4 -tx1 "$src.zst" | tr -d ' \n')
test "$magic" = "28b52ffd"

zstd -tq "$src.zst"
zstd -dq -c "$src.zst" >"$tmpdir/decoded.txt"
cmp "$tmpdir/expected.txt" "$tmpdir/decoded.txt"
decoded_sum=$(sha256sum "$tmpdir/decoded.txt" | awk '{print $1}')
test "$expected_sum" = "$decoded_sum"
