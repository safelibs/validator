#!/usr/bin/env bash
# @testcase: usage-gpg-gen-random-zero-bytes
# @title: gpg gen-random 32 bytes
# @description: Requests 32 bytes from gpg --gen-random and verifies the output stream length matches the requested byte count.
# @timeout: 180
# @tags: usage, gpg, random
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-gen-random-zero-bytes"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
passphrase=validator-passphrase
uid='Validator User <validator@example.invalid>'

make_signing_key() {
  "${gpg_batch[@]}" --passphrase '' --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1
}

make_encryption_key() {
  "${gpg_batch[@]}" --passphrase '' --quick-generate-key "$uid" rsa2048 encrypt 1d >/dev/null 2>&1
}

gpg --gen-random 0 32 >"$tmpdir/random.bin"
bytes=$(wc -c <"$tmpdir/random.bin")
test "$bytes" -eq 32
