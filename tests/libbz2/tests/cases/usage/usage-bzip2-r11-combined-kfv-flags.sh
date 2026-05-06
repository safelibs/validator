#!/usr/bin/env bash
# @testcase: usage-bzip2-r11-combined-kfv-flags
# @title: bzip2 -kfv combined short flags keep, force, and trace verbosely
# @description: Pre-creates the .bz2 target then runs bzip2 -kfv with combined short flags and confirms the original input is retained, the existing target is overwritten, and the verbose ratio line is emitted on stderr.
# @timeout: 60
# @tags: usage, compression, combined-flags, verbose
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

for i in $(seq 1 100); do
    printf 'combined-kfv payload line %02d\n' "$i"
done >"$tmpdir/in.txt"
orig_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

# Pre-existing target must be overwritten via -f.
printf 'stale placeholder\n' >"$tmpdir/in.txt.bz2"

bzip2 -kfv "$tmpdir/in.txt" 2>"$tmpdir/v.err"

# -k retained the original.
[[ -f "$tmpdir/in.txt" ]]
after_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')
[[ "$orig_sha" == "$after_sha" ]]

# -f overwrote the placeholder; new .bz2 round-trips to the input.
bzip2 -dc "$tmpdir/in.txt.bz2" >"$tmpdir/round.out"
cmp "$tmpdir/in.txt" "$tmpdir/round.out"

# -v emits a per-file ratio summary to stderr containing the input filename.
grep -F 'in.txt' "$tmpdir/v.err" >/dev/null
grep -F 'bits/byte' "$tmpdir/v.err" >/dev/null
