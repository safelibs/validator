#!/usr/bin/env bash
# @testcase: usage-minisign-r9-binary-input-roundtrip
# @title: minisign signs and verifies a binary blob
# @description: Generates a passwordless minisign keypair, signs a binary file containing arbitrary bytes, and verifies the signature with the corresponding public key.
# @timeout: 180
# @tags: usage, minisign, crypto
# @client: minisign

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

minisign -G -W -p "$tmpdir/pk" -s "$tmpdir/sk" >/dev/null

# Build a small binary blob.
python3 - "$tmpdir/blob.bin" <<'PY'
import sys
open(sys.argv[1], "wb").write(bytes(range(256)) * 4)
PY

minisign -S -W -s "$tmpdir/sk" -m "$tmpdir/blob.bin" >/dev/null
[[ -f "$tmpdir/blob.bin.minisig" ]]
minisign -V -p "$tmpdir/pk" -m "$tmpdir/blob.bin" >"$tmpdir/verify.log"
validator_assert_contains "$tmpdir/verify.log" 'Signature and comment signature verified'
