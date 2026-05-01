#!/usr/bin/env bash
# @testcase: usage-minisign-pubkey-base64-decode-batch12
# @title: minisign public key base64 payload decodes to 42 bytes
# @description: Generates a passwordless minisign keypair, extracts the second non-comment line of the public key file and base64-decodes it, asserts the decoded blob is exactly 42 bytes long (2-byte signature_algorithm + 8-byte key_id + 32-byte Ed25519 public key) and that its first two bytes are the ASCII signature algorithm tag "Ed".
# @timeout: 180
# @tags: usage, crypto, signature, minisign
# @client: minisign

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

minisign -G -p "$tmpdir/minisign.pub" -s "$tmpdir/minisign.sec" -W

# The minisign public key file is two lines: a comment and the base64 payload.
payload_line=$(grep -v '^untrusted comment' "$tmpdir/minisign.pub" | head -n1)
[ -n "$payload_line" ] || { echo "no payload line found" >&2; exit 1; }

printf '%s' "$payload_line" | base64 -d >"$tmpdir/decoded.bin"
size=$(stat -c '%s' "$tmpdir/decoded.bin")
if [ "$size" != "42" ]; then
    echo "decoded payload is $size bytes, expected 42" >&2
    exit 1
fi

prefix=$(head -c 2 "$tmpdir/decoded.bin")
if [ "$prefix" != "Ed" ]; then
    echo "signature algorithm prefix is not 'Ed': $(printf '%s' "$prefix" | xxd -p)" >&2
    exit 1
fi

echo "ok $size $prefix"
