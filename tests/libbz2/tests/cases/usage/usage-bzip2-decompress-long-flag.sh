#!/usr/bin/env bash
# @testcase: usage-bzip2-decompress-long-flag
# @title: bzip2 --decompress is the long-form alias for -d
# @description: Round-trips a payload by compressing with bzip2 -c and then decompressing with bzip2 --decompress -c, confirming the long --decompress flag behaves identically to the short -d alias on both file-arg and stdin variants.
# @timeout: 180
# @tags: usage, bzip2, flags
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c 'import sys
for i in range(512):
    sys.stdout.write(f"long-form decompress payload row {i}\n")' >"$tmpdir/in.txt"
expected_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

# Reference compressed stream produced via the canonical short flag.
bzip2 -c "$tmpdir/in.txt" >"$tmpdir/in.bz2"

# Variant 1: --decompress with -c on a file-arg path.
bzip2 --decompress -c "$tmpdir/in.bz2" >"$tmpdir/long-file.txt"
cmp "$tmpdir/in.txt" "$tmpdir/long-file.txt"
[[ "$(sha256sum "$tmpdir/long-file.txt" | awk '{print $1}')" == "$expected_sha" ]]

# Variant 2: --decompress reading from stdin must match -d on stdin.
bzip2 --decompress -c - <"$tmpdir/in.bz2" >"$tmpdir/long-stdin.txt"
bzip2 -d -c - <"$tmpdir/in.bz2" >"$tmpdir/short-stdin.txt"
cmp "$tmpdir/long-stdin.txt" "$tmpdir/short-stdin.txt"
cmp "$tmpdir/long-stdin.txt" "$tmpdir/in.txt"

# Variant 3: --decompress without -c replaces the input file with the
# decompressed payload, matching the documented short-flag behaviour.
cp "$tmpdir/in.bz2" "$tmpdir/replace.bz2"
bzip2 --decompress "$tmpdir/replace.bz2"
[[ ! -e "$tmpdir/replace.bz2" ]] || {
  printf 'expected --decompress to remove the .bz2 file in place\n' >&2
  exit 1
}
validator_require_file "$tmpdir/replace"
cmp "$tmpdir/in.txt" "$tmpdir/replace"
