#!/usr/bin/env bash
# @testcase: usage-coreutils-od-hex-bytes
# @title: coreutils od hex bytes
# @description: Dumps two ASCII bytes with od -tx1 and verifies the hexadecimal byte values 41 and 42.
# @timeout: 180
# @tags: usage, coreutils, binary
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-coreutils-od-hex-bytes"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'AB' >"$tmpdir/in.bin"
od -An -tx1 "$tmpdir/in.bin" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" '41 42'
