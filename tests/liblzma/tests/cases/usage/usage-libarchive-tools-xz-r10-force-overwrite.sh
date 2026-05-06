#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r10-force-overwrite
# @title: xz --force overwrites existing target
# @description: Pre-creates a stale .xz file then re-encodes the source with xz --force, confirming the target is overwritten and decoding produces the new payload.
# @timeout: 120
# @tags: usage, xz, force, overwrite
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'stale placeholder\n' >"$tmpdir/data.txt.xz"
printf 'force overwrite payload abcdefg\n' >"$tmpdir/data.txt"
src_sha=$(sha256sum "$tmpdir/data.txt" | awk '{print $1}')

xz --force --keep "$tmpdir/data.txt"

magic_hex=$(head -c 6 "$tmpdir/data.txt.xz" | od -An -tx1 | tr -d ' \n')
test "$magic_hex" = "fd377a585a00"

xz --decompress --stdout "$tmpdir/data.txt.xz" >"$tmpdir/decoded.txt"
out_sha=$(sha256sum "$tmpdir/decoded.txt" | awk '{print $1}')
test "$src_sha" = "$out_sha"
