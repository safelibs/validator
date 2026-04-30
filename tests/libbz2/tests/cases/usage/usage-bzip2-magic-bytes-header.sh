#!/usr/bin/env bash
# @testcase: usage-bzip2-magic-bytes-header
# @title: bzip2 emits BZh magic header
# @description: Compresses a payload and verifies the produced .bz2 stream begins with the bzip2 BZh magic bytes.
# @timeout: 120
# @tags: usage, compression, format
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'magic header payload\n' >"$tmpdir/in.txt"
bzip2 -c "$tmpdir/in.txt" >"$tmpdir/in.txt.bz2"
validator_require_file "$tmpdir/in.txt.bz2"

magic=$(head -c 3 "$tmpdir/in.txt.bz2")
if [[ "$magic" != "BZh" ]]; then
  printf 'expected BZh magic, got: %q\n' "$magic" >&2
  od -An -c -N 4 "$tmpdir/in.txt.bz2" >&2 || true
  exit 1
fi

# The fourth byte encodes the block size '1'..'9' for the default level.
fourth=$(dd if="$tmpdir/in.txt.bz2" bs=1 count=1 skip=3 status=none)
case "$fourth" in
  [1-9]) ;;
  *) printf 'unexpected block-size byte: %q\n' "$fourth" >&2; exit 1 ;;
esac

file "$tmpdir/in.txt.bz2" >"$tmpdir/file.out"
validator_assert_contains "$tmpdir/file.out" 'bzip2 compressed data'
