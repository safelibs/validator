#!/usr/bin/env bash
# @testcase: usage-bzip2-r15-bzip2-q-suffix-warning-suppressed
# @title: bzip2 -dq on a .bz2 file with a wrong rename emits a warning that -q would have suppressed
# @description: Compresses a payload, renames the .bz2 file to an unrecognised .dat suffix, then runs two parallel decode invocations writing to disk (not stdout, where bzip2 omits the suffix warning): one with "bzip2 -d" (no quiet flag) capturing stderr, and one with "bzip2 -d -q" (quiet flag). Asserts the loud invocation prints non-empty stderr (the "Can't guess original name" warning), the quiet invocation prints empty stderr, and both produce decoded outputs whose sha256 matches the original — pinning that -q only changes warning chatter, not decode correctness.
# @timeout: 60
# @tags: usage, bzip2, quiet, suffix
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r15 suffix-warning payload alpha beta gamma\n' >"$tmpdir/in.txt"
src_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

bzip2 -c "$tmpdir/in.txt" >"$tmpdir/blob.dat"

# Loud decode: bzip2 -d on a .dat input warns about the unrecognised suffix.
cp "$tmpdir/blob.dat" "$tmpdir/loud.dat"
bzip2 -d "$tmpdir/loud.dat" 2>"$tmpdir/loud.err"

# Quiet decode: -q on the same kind of input.
cp "$tmpdir/blob.dat" "$tmpdir/quiet.dat"
bzip2 -d -q "$tmpdir/quiet.dat" 2>"$tmpdir/quiet.err"

# Loud stderr is non-empty, quiet stderr is empty.
[[ -s "$tmpdir/loud.err" ]]
[[ ! -s "$tmpdir/quiet.err" ]]

# bzip2 names the output ".out" suffix when it can't guess; both decoded files match the source.
[[ -f "$tmpdir/loud.dat.out" ]]
[[ -f "$tmpdir/quiet.dat.out" ]]
loud_sha=$(sha256sum "$tmpdir/loud.dat.out" | awk '{print $1}')
quiet_sha=$(sha256sum "$tmpdir/quiet.dat.out" | awk '{print $1}')
test "$src_sha" = "$loud_sha"
test "$src_sha" = "$quiet_sha"
