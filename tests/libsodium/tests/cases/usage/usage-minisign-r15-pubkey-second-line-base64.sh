#!/usr/bin/env bash
# @testcase: usage-minisign-r15-pubkey-second-line-base64
# @title: minisign -G writes a public key file whose second line is a base64-only blob
# @description: Generates a passwordless minisign keypair, asserts the resulting public-key file has exactly two non-empty lines, asserts line 1 begins with 'untrusted comment:' (minisign banner), asserts line 2 contains only base64 alphabet characters (A-Z a-z 0-9 + / =) and is between 50 and 80 characters long — exercising minisign's libsodium-backed Ed25519 keygen and pubkey serialization.
# @timeout: 60
# @tags: usage, minisign, pubkey, base64, r15
# @client: minisign

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

minisign -G -W -p "$tmpdir/m.pub" -s "$tmpdir/m.sec" >/dev/null

[[ -s "$tmpdir/m.pub" ]]

# Line 1: comment banner.
line1=$(LC_ALL=C sed -n '1p' "$tmpdir/m.pub")
[[ "$line1" == untrusted\ comment:* ]] || {
  printf 'unexpected pubkey line 1: %s\n' "$line1" >&2
  exit 1
}

# Line 2: base64 blob (minisign signature/key material is base64-encoded).
line2=$(LC_ALL=C sed -n '2p' "$tmpdir/m.pub")
[[ -n "$line2" ]]
[[ ${#line2} -ge 50 ]]
[[ ${#line2} -le 80 ]]
LC_ALL=C grep -Eq '^[A-Za-z0-9+/]+=*$' <<<"$line2" || {
  printf 'pubkey line 2 contains non-base64 characters: %s\n' "$line2" >&2
  exit 1
}

# File should be exactly 2 non-empty lines.
nonempty=$(LC_ALL=C grep -cE '.' "$tmpdir/m.pub")
[[ "$nonempty" -eq 2 ]]
