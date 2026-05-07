#!/usr/bin/env bash
# @testcase: usage-minisign-r13-trusted-vs-untrusted-comment
# @title: minisign signs with distinct trusted and untrusted comments preserved through verify
# @description: Generates a keypair, signs a payload with separate -c and -t comments, asserts both labels appear in the .minisig metadata, and asserts the trusted comment surfaces in the verify output.
# @timeout: 180
# @tags: usage, minisign, comment
# @client: minisign

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

minisign -G -W -p "$tmpdir/m.pub" -s "$tmpdir/m.sec"

printf 'r13 trust split payload\n' >"$tmpdir/msg.txt"
unt='r13 untrusted note'
trust='r13 trusted comment value'

minisign -Sm "$tmpdir/msg.txt" \
  -s "$tmpdir/m.sec" \
  -c "$unt" \
  -t "$trust" \
  -x "$tmpdir/msg.txt.minisig"

validator_require_file "$tmpdir/msg.txt.minisig"

# .minisig must carry both labels and both supplied strings.
validator_assert_contains "$tmpdir/msg.txt.minisig" 'untrusted comment:'
validator_assert_contains "$tmpdir/msg.txt.minisig" 'trusted comment:'
validator_assert_contains "$tmpdir/msg.txt.minisig" "$unt"
validator_assert_contains "$tmpdir/msg.txt.minisig" "$trust"

# Trusted comment must surface in verify output.
minisign -Vm "$tmpdir/msg.txt" -p "$tmpdir/m.pub" -x "$tmpdir/msg.txt.minisig" >"$tmpdir/v.out"
validator_assert_contains "$tmpdir/v.out" "$trust"
validator_assert_contains "$tmpdir/v.out" 'Signature and comment signature verified'
