#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-xz-r14-check-sha256-list-column
# @title: xz --check=sha256 surfaces SHA-256 in the --robot --list totals column
# @description: Compresses a payload with "xz --check=sha256 -c" and runs "xz --robot --list" on the result, asserting the totals row's check column equals SHA-256, complementing the r12 default-CRC64 case by pinning the explicit-sha256 path.
# @timeout: 60
# @tags: usage, xz, check, sha256
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'sha256 list column payload\n' >"$tmpdir/in.txt"
src_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

xz --check=sha256 -c "$tmpdir/in.txt" >"$tmpdir/out.xz"

xz --robot --list "$tmpdir/out.xz" >"$tmpdir/list.txt"
totals_check=$(awk '$1=="totals"{print $7}' "$tmpdir/list.txt")
test "$totals_check" = "SHA-256"

xz -dc "$tmpdir/out.xz" >"$tmpdir/decoded.txt"
test "$src_sha" = "$(sha256sum "$tmpdir/decoded.txt" | awk '{print $1}')"
