#!/usr/bin/env bash
# @testcase: usage-minisign-detached-text
# @title: minisign detached text
# @description: Signs and verifies a text payload with minisign detached signature files.
# @timeout: 180
# @tags: usage, crypto, signature
# @client: minisign

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-minisign-detached-text"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'detached minisign payload\n' >"$tmpdir/message.txt"
minisign -G -p "$tmpdir/minisign.pub" -s "$tmpdir/minisign.sec" -W
minisign -Sm "$tmpdir/message.txt" -s "$tmpdir/minisign.sec" -x "$tmpdir/message.minisig"
minisign -Vm "$tmpdir/message.txt" -p "$tmpdir/minisign.pub" -x "$tmpdir/message.minisig" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Signature and comment signature verified'
