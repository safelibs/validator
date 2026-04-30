#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-batch16-keep-force-overwrite
# @title: xz --keep --force overwrites target
# @description: Verifies xz --keep --force overwrites an existing .xz target and the resulting archive still round-trips through bsdcat.
# @timeout: 180
# @tags: usage, xz, force
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'first payload\n' >"$tmpdir/data.txt"
xz --keep "$tmpdir/data.txt"
validator_require_file "$tmpdir/data.txt"
validator_require_file "$tmpdir/data.txt.xz"
sha_first=$(sha256sum "$tmpdir/data.txt.xz" | awk '{print $1}')

# Replace source with new content and force overwrite of the .xz file.
printf 'replacement payload row 1\nrow 2 with extra bytes for compression\n' >"$tmpdir/data.txt"
xz --keep --force "$tmpdir/data.txt"
validator_require_file "$tmpdir/data.txt.xz"
sha_second=$(sha256sum "$tmpdir/data.txt.xz" | awk '{print $1}')

# The .xz file must have changed (new content compressed in place).
test "$sha_first" != "$sha_second"

bsdcat "$tmpdir/data.txt.xz" >"$tmpdir/decoded.txt"
cmp "$tmpdir/data.txt" "$tmpdir/decoded.txt"
