#!/usr/bin/env bash
# @testcase: usage-coreutils-od-decimal-bytes
# @title: coreutils od unsigned decimal byte dump
# @description: Dumps bytes as unsigned decimals via od -An -tu1 and verifies the resulting numeric stream.
# @timeout: 180
# @tags: usage, coreutils, binary
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-coreutils-od-decimal-bytes"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'AB\n' >"$tmpdir/in.bin"
od -An -tu1 "$tmpdir/in.bin" | tr -s ' ' >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" ' 65 66 10'
