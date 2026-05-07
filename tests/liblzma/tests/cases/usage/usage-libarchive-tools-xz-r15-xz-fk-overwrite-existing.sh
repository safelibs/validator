#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r15-xz-fk-overwrite-existing
# @title: xz -fk forcibly overwrites an existing .xz target while preserving the source
# @description: Compresses a payload to in.txt.xz, then changes the source contents and re-runs "xz -fk in.txt" — the -f flag forces overwrite of the existing .xz target while -k keeps the new source on disk. Asserts the .xz file now decompresses to the new payload (not the original), the source remains intact, and the round-trip sha256 matches the new payload. Distinct from r10/r13 force-overwrite cases by combining -f with -k against an existing on-disk target.
# @timeout: 60
# @tags: usage, xz, force, keep
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# First write: compress an initial payload into in.txt.xz.
printf 'r15 fk first payload\n' >"$tmpdir/in.txt"
xz -k "$tmpdir/in.txt"
[[ -f "$tmpdir/in.txt.xz" ]]
[[ -f "$tmpdir/in.txt" ]]

# Replace the source with new contents.
printf 'r15 fk second payload longer\n' >"$tmpdir/in.txt"
new_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

# -fk: force overwrite the existing .xz target, keep the source.
xz -fk "$tmpdir/in.txt"
[[ -f "$tmpdir/in.txt.xz" ]]
[[ -f "$tmpdir/in.txt" ]]

# Source is preserved with the second-payload bytes.
test "$new_sha" = "$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')"

# .xz now decodes to the second payload.
xz -dc "$tmpdir/in.txt.xz" >"$tmpdir/decoded.txt"
test "$new_sha" = "$(sha256sum "$tmpdir/decoded.txt" | awk '{print $1}')"
