#!/usr/bin/env bash
# @testcase: usage-minisign-r18-prehashed-sign-verify-roundtrip
# @title: minisign -H prehashed sign produces a signature that verifies under the same pubkey
# @description: Generates a passwordless keypair, signs a payload with the prehashed (-H) algorithm and writes the signature to a file, asserts the signature file is non-empty, then verifies the signature with minisign -V against the original payload and the matching public key, asserting verify returns exit zero.
# @timeout: 60
# @tags: usage, minisign, sign, prehashed, r18
# @client: minisign

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

minisign -G -W -p "$tmpdir/k.pub" -s "$tmpdir/k.sec" >/dev/null

printf 'r18 prehashed payload\n' >"$tmpdir/m.txt"

minisign -S -H -s "$tmpdir/k.sec" -m "$tmpdir/m.txt" -x "$tmpdir/prehash.sig" -W </dev/null >/dev/null

[[ -s "$tmpdir/prehash.sig" ]]

minisign -V -p "$tmpdir/k.pub" -m "$tmpdir/m.txt" -x "$tmpdir/prehash.sig" >/dev/null

echo "ok prehashed signature verified"
