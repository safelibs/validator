#!/usr/bin/env bash
# @testcase: usage-minisign-r11-empty-payload-sign-verify
# @title: minisign signs and verifies a zero-byte payload
# @description: Generates a passwordless minisign keypair, signs an empty file with the legacy non-prehashed mode, and asserts the resulting .minisig verifies cleanly under the matching public key — confirming minisign accepts zero-length input as a valid message.
# @timeout: 120
# @tags: usage, minisign, edge
# @client: minisign

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

minisign -G -W -p "$tmpdir/pk" -s "$tmpdir/sk" >/dev/null

: >"$tmpdir/empty.bin"
[[ ! -s "$tmpdir/empty.bin" ]] || { echo "fixture not zero-length" >&2; exit 1; }

minisign -S -W -s "$tmpdir/sk" -m "$tmpdir/empty.bin" >/dev/null
[[ -f "$tmpdir/empty.bin.minisig" ]] || { echo "no signature emitted" >&2; exit 2; }

minisign -V -p "$tmpdir/pk" -m "$tmpdir/empty.bin" >"$tmpdir/v.log"
validator_assert_contains "$tmpdir/v.log" 'Signature and comment signature verified'
echo ok
