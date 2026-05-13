#!/usr/bin/env bash
# @testcase: usage-minisign-r16-sign-verify-message-roundtrip
# @title: minisign signs a fresh payload with -S and verifies it with -V using a generated keypair
# @description: Generates a passwordless minisign keypair, writes a fixed payload, signs it with minisign -S producing a .minisig file, asserts the signature file exists and is non-empty, then verifies with minisign -V against the public key and asserts the verifier exits 0 and emits the canonical "Signature and comment signature verified" line.
# @timeout: 60
# @tags: usage, minisign, sign, verify, r16
# @client: minisign

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

minisign -G -W -p "$tmpdir/k.pub" -s "$tmpdir/k.sec" >/dev/null
[[ -s "$tmpdir/k.pub" ]]
[[ -s "$tmpdir/k.sec" ]]

printf 'r16 minisign payload\n' >"$tmpdir/msg.txt"

minisign -S -s "$tmpdir/k.sec" -m "$tmpdir/msg.txt" -W </dev/null >/dev/null
[[ -s "$tmpdir/msg.txt.minisig" ]]

minisign -V -p "$tmpdir/k.pub" -m "$tmpdir/msg.txt" >"$tmpdir/verify.out"
validator_assert_contains "$tmpdir/verify.out" 'Signature and comment signature verified'
