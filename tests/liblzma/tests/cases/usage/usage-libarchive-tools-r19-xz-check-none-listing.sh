#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r19-xz-check-none-listing
# @title: xz --check=none --list reports None integrity-check for the produced stream
# @description: Compresses a payload with xz --check=none and runs xz --list against the output, asserting the Check column reports "None", pinning the no-integrity-check path through liblzma.
# @timeout: 60
# @tags: usage, xz, check, none, r19
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r19 xz check none payload\n' >"$tmpdir/data.txt"
xz --check=none -c "$tmpdir/data.txt" >"$tmpdir/data.xz"

xz --list "$tmpdir/data.xz" >"$tmpdir/list.txt"
validator_assert_contains "$tmpdir/list.txt" 'None'
