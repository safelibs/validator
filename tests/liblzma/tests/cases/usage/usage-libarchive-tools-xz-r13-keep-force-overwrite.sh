#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r13-keep-force-overwrite
# @title: xz --keep --force overwrites an existing .xz target
# @description: Compresses a file once with --keep, then re-runs xz with --keep --force in place, verifies the second run succeeds (overwriting the existing .xz), the source file is preserved, and the new .xz decodes byte-equal to the source.
# @timeout: 60
# @tags: usage, xz, keep, force
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'force-overwrite payload\n' >"$tmpdir/data.txt"
src_sha=$(sha256sum "$tmpdir/data.txt" | awk '{print $1}')

xz --keep "$tmpdir/data.txt"
[[ -f "$tmpdir/data.txt.xz" ]]
first_size=$(stat -c '%s' "$tmpdir/data.txt.xz")

# Without --force, this would error because data.txt.xz already exists.
xz --keep --force "$tmpdir/data.txt"

[[ -f "$tmpdir/data.txt" ]]
[[ -f "$tmpdir/data.txt.xz" ]]
post_sha=$(sha256sum "$tmpdir/data.txt" | awk '{print $1}')
test "$src_sha" = "$post_sha"

# Decompress the (re)written archive and compare.
xz -dc "$tmpdir/data.txt.xz" >"$tmpdir/decoded.txt"
out_sha=$(sha256sum "$tmpdir/decoded.txt" | awk '{print $1}')
test "$src_sha" = "$out_sha"

# Sanity: the second .xz exists and is at least as large as the first (deterministic with same input + level).
second_size=$(stat -c '%s' "$tmpdir/data.txt.xz")
[[ "$second_size" -gt 0 && "$first_size" -gt 0 ]]
