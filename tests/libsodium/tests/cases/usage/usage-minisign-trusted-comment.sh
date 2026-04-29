#!/usr/bin/env bash
# @testcase: usage-minisign-trusted-comment
# @title: minisign trusted comment
# @description: Signs a payload with a trusted minisign comment and verifies the signed metadata.
# @timeout: 180
# @tags: usage, crypto
# @client: minisign

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    printf 'payload
' >"$tmpdir/message.txt"
minisign -G -p "$tmpdir/minisign.pub" -s "$tmpdir/minisign.sec" -W
minisign -Sm "$tmpdir/message.txt" -s "$tmpdir/minisign.sec" -t 'validator comment' -x "$tmpdir/message.txt.minisig"
minisign -Vm "$tmpdir/message.txt" -p "$tmpdir/minisign.pub" -x "$tmpdir/message.txt.minisig" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'validator comment'
