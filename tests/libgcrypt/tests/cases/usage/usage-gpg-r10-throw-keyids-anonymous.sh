#!/usr/bin/env bash
# @testcase: usage-gpg-r10-throw-keyids-anonymous
# @title: gpg --throw-keyids zeroes the recipient key id in PKESK
# @description: Encrypts to an Ed25519/Cv25519 key with --throw-keyids and verifies the resulting public-key encrypted session key packet reports an anonymous (all-zero) keyid via gpg --list-packets.
# @timeout: 240
# @tags: usage, gpg, encryption, anonymous
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

uid='Validator R10 ThrowKeyids <r10-throw@example.invalid>'
gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --quick-generate-key "$uid" default default 1d >/dev/null 2>&1

printf 'throw-keyids payload\n' >"$tmpdir/plain.txt"
gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --throw-keyids --trust-model always \
  -e -r "$uid" -o "$tmpdir/cipher.gpg" "$tmpdir/plain.txt"

gpg --batch --list-packets "$tmpdir/cipher.gpg" >"$tmpdir/packets" 2>&1
validator_assert_contains "$tmpdir/packets" ':pubkey enc packet:'
grep -qE 'keyid 0+' "$tmpdir/packets" || {
  printf 'expected anonymous (zero) keyid in pubkey enc packet\n' >&2
  sed -n '1,80p' "$tmpdir/packets" >&2
  exit 1
}
