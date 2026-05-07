#!/usr/bin/env bash
# @testcase: usage-minisign-r13-verify-payload-modified-fails
# @title: minisign -V verifies the original payload and rejects a modified payload
# @description: Generates a passwordless minisign keypair, signs a payload, asserts -V verify succeeds against the unmodified file, then mutates the payload and asserts -V exits non-zero against the tampered file.
# @timeout: 180
# @tags: usage, minisign, verify, signature
# @client: minisign

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

minisign -G -W -p "$tmpdir/m.pub" -s "$tmpdir/m.sec"

printf 'r13 minisign verify payload\n' >"$tmpdir/msg.txt"
minisign -Sm "$tmpdir/msg.txt" -s "$tmpdir/m.sec" -x "$tmpdir/msg.txt.minisig"

# Verify against the original payload succeeds.
minisign -Vm "$tmpdir/msg.txt" -p "$tmpdir/m.pub" -x "$tmpdir/msg.txt.minisig" >"$tmpdir/v.out"
validator_assert_contains "$tmpdir/v.out" 'Signature and comment signature verified'

# Mutate the payload — verify must fail.
printf 'r13 minisign verify payload TAMPERED\n' >"$tmpdir/msg.txt"
if minisign -Vm "$tmpdir/msg.txt" -p "$tmpdir/m.pub" -x "$tmpdir/msg.txt.minisig" >/dev/null 2>&1; then
  echo 'verify unexpectedly accepted tampered payload' >&2
  exit 1
fi
