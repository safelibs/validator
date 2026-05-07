#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r15-xz-q-suppresses-verbose-line
# @title: xz -q suppresses the verbose stats line that -v emits to stderr
# @description: Compresses a payload to .xz, then runs two parallel verbose decompressions: "xz -d -v" (verbose stderr enabled) and "xz -d -v -q" (the -q flag overrides the verbosity bump). Asserts the verbose form prints non-empty stderr containing the input filename, while the -q form prints empty stderr, and both write the same correctly recovered payload back to disk matching the source sha256 — pinning the -q quietness flag against the -v verbose flag in tandem.
# @timeout: 60
# @tags: usage, xz, quiet, verbose
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r15 xz quiet vs verbose payload alpha beta gamma\n' >"$tmpdir/in.txt"
src_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

# Verbose decode that keeps the source compressed file alive for parallel runs.
cp_xz() { xz -c "$tmpdir/in.txt" >"$1"; }

cp_xz "$tmpdir/loud.xz"
xz -d -v "$tmpdir/loud.xz" 2>"$tmpdir/loud.err"
[[ -f "$tmpdir/loud" ]]
[[ -s "$tmpdir/loud.err" ]]
grep -F "$tmpdir/loud.xz" "$tmpdir/loud.err" >/dev/null

cp_xz "$tmpdir/quiet.xz"
xz -d -v -q "$tmpdir/quiet.xz" 2>"$tmpdir/quiet.err"
[[ -f "$tmpdir/quiet" ]]
[[ ! -s "$tmpdir/quiet.err" ]]

loud_sha=$(sha256sum "$tmpdir/loud" | awk '{print $1}')
quiet_sha=$(sha256sum "$tmpdir/quiet" | awk '{print $1}')
test "$src_sha" = "$loud_sha"
test "$src_sha" = "$quiet_sha"
