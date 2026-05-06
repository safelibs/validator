#!/usr/bin/env bash
# @testcase: usage-minisign-r11-trusted-comment-stable-across-runs
# @title: minisign -t pins the trusted comment text and survives verification
# @description: Generates a passwordless minisign keypair, signs a payload twice with the same explicit -t trusted comment string, asserts both .minisig files contain the trusted comment line verbatim, and verifies that minisign -V -o prints the trusted comment to stdout from a successful verification.
# @timeout: 180
# @tags: usage, minisign, trusted-comment
# @client: minisign

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

minisign -G -W -p "$tmpdir/pk" -s "$tmpdir/sk" >/dev/null

trusted="validator-r11 build 7 by alice"
printf 'minisign r11 trusted comment payload\n' >"$tmpdir/p.txt"

minisign -S -W -s "$tmpdir/sk" -m "$tmpdir/p.txt" \
    -t "$trusted" -x "$tmpdir/run1.minisig" >/dev/null
minisign -S -W -s "$tmpdir/sk" -m "$tmpdir/p.txt" \
    -t "$trusted" -x "$tmpdir/run2.minisig" >/dev/null

validator_assert_contains "$tmpdir/run1.minisig" "trusted comment: $trusted"
validator_assert_contains "$tmpdir/run2.minisig" "trusted comment: $trusted"

minisign -V -p "$tmpdir/pk" -m "$tmpdir/p.txt" -x "$tmpdir/run1.minisig" -o \
    >"$tmpdir/verify.out" 2>"$tmpdir/verify.err"
validator_assert_contains "$tmpdir/verify.err" "Trusted comment: $trusted"
echo ok
