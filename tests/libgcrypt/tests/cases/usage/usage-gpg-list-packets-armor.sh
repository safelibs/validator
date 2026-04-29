#!/usr/bin/env bash
# @testcase: usage-gpg-list-packets-armor
# @title: gpg list packets armor
# @description: Lists packets from an armored detached signature and verifies packet metadata is emitted.
# @timeout: 180
# @tags: usage, crypto, packets
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-list-packets-armor"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"
gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
passphrase=validator-passphrase
uid='Validator More <validator-more@example.invalid>'

make_signing_key() {
  "${gpg_batch[@]}" --passphrase '' --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1
}

make_signing_key
printf 'packet payload\n' >"$tmpdir/plain.txt"
"${gpg_batch[@]}" --armor --detach-sign -o "$tmpdir/plain.asc" "$tmpdir/plain.txt"
gpg --list-packets "$tmpdir/plain.asc" >"$tmpdir/out" 2>&1 || true
validator_assert_contains "$tmpdir/out" 'signature packet'
