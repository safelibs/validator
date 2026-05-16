#!/usr/bin/env bash
# @testcase: usage-minisign-r21-generate-sign-verify-stdin-payload
# @title: minisign -G generates a keypair, -S signs a payload, -V verifies via -p public-key-file
# @description: Generates a passwordless minisign keypair with -G -W, writes a payload file, signs it with -S using the secret key, and verifies it with -V -p public-key-file, asserting the verify command exits zero and emits the documented success banner over a libsodium-Ed25519-backed round-trip.
# @timeout: 60
# @tags: usage, sodium, minisign, sign-verify, r21
# @client: minisign

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cd "$tmpdir"

minisign -G -W -p pub.key -s sec.key >/dev/null
echo "payload contents r21" >payload.bin
minisign -S -s sec.key -m payload.bin >/dev/null

# Verify with -p pointing at the public-key-file
minisign -V -p pub.key -m payload.bin >out.txt

validator_assert_contains out.txt 'Signature and comment signature verified'
