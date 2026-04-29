#!/usr/bin/env bash
# @testcase: usage-gpg-tampered-signature-reject
# @title: gpg rejects tampered signature
# @description: Verifies that gpg rejects a detached signature after the signed payload changes.
# @timeout: 180
# @tags: usage, crypto, negative
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-tampered-signature-reject"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"
gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
passphrase=validator-passphrase
uid='Validator Extra <validator-extra@example.invalid>'

make_signing_key() {
  "${gpg_batch[@]}" --passphrase '' --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1
}

make_encryption_key() {
  "${gpg_batch[@]}" --passphrase '' --quick-generate-key "$uid" rsa2048 encrypt 1d >/dev/null 2>&1
}

make_signing_key
printf 'signed payload\n' >"$tmpdir/plain.txt"
"${gpg_batch[@]}" --detach-sign -o "$tmpdir/plain.sig" "$tmpdir/plain.txt"
printf 'tampered payload\n' >"$tmpdir/plain.txt"
if gpg --verify "$tmpdir/plain.sig" "$tmpdir/plain.txt" >"$tmpdir/out" 2>&1; then
  printf 'tampered signature unexpectedly verified\n' >&2
  exit 1
fi
validator_assert_contains "$tmpdir/out" 'BAD signature'
