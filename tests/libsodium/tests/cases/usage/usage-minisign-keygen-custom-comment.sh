#!/usr/bin/env bash
# @testcase: usage-minisign-keygen-custom-comment
# @title: minisign signs with custom trusted comment
# @description: Generates a passwordless minisign keypair, signs a payload with -t supplying a custom trusted comment, and verifies that minisign -V reports the comment signature verified and the trusted comment line round-trips into the .minisig file.
# @timeout: 180
# @tags: usage, crypto, keygen, minisign
# @client: minisign

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

custom_comment='validator custom trusted comment'
minisign -G -p "$tmpdir/minisign.pub" -s "$tmpdir/minisign.sec" -W

validator_require_file "$tmpdir/minisign.pub"
validator_require_file "$tmpdir/minisign.sec"

# minisign public key files have two lines: the untrusted comment then the
# base64 key. The base64 line must be at least 40 chars to match minisign's
# Ed25519+keyid encoding.
key_line=$(sed -n '2p' "$tmpdir/minisign.pub")
if [[ ${#key_line} -lt 40 ]]; then
  echo "minisign public key line too short: ${#key_line}" >&2
  exit 1
fi

# Sign a payload with a custom trusted comment; -t embeds it into the
# signature file and binds it to the second Ed25519 signature.
printf 'custom comment payload\n' >"$tmpdir/message.txt"
minisign -Sm "$tmpdir/message.txt" -s "$tmpdir/minisign.sec" \
  -x "$tmpdir/message.txt.minisig" -t "$custom_comment"

validator_assert_contains "$tmpdir/message.txt.minisig" "$custom_comment"

minisign -Vm "$tmpdir/message.txt" -p "$tmpdir/minisign.pub" \
  -x "$tmpdir/message.txt.minisig" >"$tmpdir/verify.out"
validator_assert_contains "$tmpdir/verify.out" 'Signature and comment signature verified'
validator_assert_contains "$tmpdir/verify.out" "$custom_comment"
