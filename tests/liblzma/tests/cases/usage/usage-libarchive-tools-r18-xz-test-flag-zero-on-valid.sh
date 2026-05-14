#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r18-xz-test-flag-zero-on-valid
# @title: xz -t exits zero on a well-formed .xz file
# @description: Compresses a payload with xz then runs xz -t against the result and asserts the integrity test exits with status zero, pinning that valid xz streams pass the integrity-check verb.
# @timeout: 60
# @tags: usage, xz, test, integrity, r18
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r18 xz-test valid payload\n' >"$tmpdir/in.txt"
xz -c "$tmpdir/in.txt" >"$tmpdir/in.xz"

xz -t "$tmpdir/in.xz"
