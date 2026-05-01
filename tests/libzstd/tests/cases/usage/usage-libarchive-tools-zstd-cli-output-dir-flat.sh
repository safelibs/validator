#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-cli-output-dir-flat
# @title: zstd CLI --output-dir-flat collects outputs in one directory
# @description: Compresses several input files from different subdirectories with --output-dir-flat=DIR and asserts each .zst output lands directly in the flat target directory (without recreating the source tree), each carries the zstd magic, and each round-trips byte-for-byte to its source.
# @timeout: 180
# @tags: usage, archive, zstd, cli, output-dir
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src/sub" "$tmpdir/flat"
python3 -c 'import sys
sys.stdout.buffer.write(b"flat-output alpha row\n" * 256)' >"$tmpdir/src/alpha.bin"
python3 -c 'import sys
sys.stdout.buffer.write(b"flat-output beta row\n" * 256)' >"$tmpdir/src/sub/beta.bin"
sum_alpha=$(sha256sum "$tmpdir/src/alpha.bin" | awk '{print $1}')
sum_beta=$(sha256sum "$tmpdir/src/sub/beta.bin" | awk '{print $1}')

zstd -q --output-dir-flat="$tmpdir/flat" \
  "$tmpdir/src/alpha.bin" "$tmpdir/src/sub/beta.bin"

validator_require_file "$tmpdir/flat/alpha.bin.zst"
validator_require_file "$tmpdir/flat/beta.bin.zst"
# Source directory structure must NOT be recreated under the flat dir.
[[ ! -e "$tmpdir/flat/sub" ]] || {
  echo "output-dir-flat must not recreate sub/" >&2
  exit 1
}

for f in "$tmpdir/flat/alpha.bin.zst" "$tmpdir/flat/beta.bin.zst"; do
  m=$(od -An -N4 -tx1 "$f" | tr -d ' \n')
  test "$m" = "28b52ffd"
done

zstd -dq -c "$tmpdir/flat/alpha.bin.zst" >"$tmpdir/alpha.out"
zstd -dq -c "$tmpdir/flat/beta.bin.zst" >"$tmpdir/beta.out"
test "$(sha256sum "$tmpdir/alpha.out" | awk '{print $1}')" = "$sum_alpha"
test "$(sha256sum "$tmpdir/beta.out" | awk '{print $1}')" = "$sum_beta"
