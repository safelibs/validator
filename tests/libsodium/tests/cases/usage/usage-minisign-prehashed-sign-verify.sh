#!/usr/bin/env bash
# @testcase: usage-minisign-prehashed-sign-verify
# @title: minisign prehashed sign and verify
# @description: Generates a passwordless minisign keypair, signs a payload in prehashed mode (-H), and verifies the resulting signature.
# @timeout: 180
# @tags: usage, crypto, signature, minisign
# @client: minisign

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'prehashed minisign payload\n' >"$tmpdir/message.txt"
minisign -G -p "$tmpdir/minisign.pub" -s "$tmpdir/minisign.sec" -W
minisign -SHm "$tmpdir/message.txt" -s "$tmpdir/minisign.sec" -x "$tmpdir/message.txt.minisig"
validator_require_file "$tmpdir/message.txt.minisig"
minisign -Vm "$tmpdir/message.txt" -p "$tmpdir/minisign.pub" -x "$tmpdir/message.txt.minisig" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Signature and comment signature verified'
