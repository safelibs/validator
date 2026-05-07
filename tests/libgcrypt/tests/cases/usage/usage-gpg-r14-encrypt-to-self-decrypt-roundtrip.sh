#!/usr/bin/env bash
# @testcase: usage-gpg-r14-encrypt-to-self-decrypt-roundtrip
# @title: gpg --encrypt to a self-generated recipient round-trips through --decrypt
# @description: Generates an Ed25519/Curve25519 default-future key pair under an ephemeral GNUPGHOME, encrypts a fixed payload to that uid with --trust-model always, decrypts the resulting OpenPGP message, and asserts the recovered plaintext is byte-identical to the original via cmp.
# @timeout: 240
# @tags: usage, gpg, encrypt, decrypt, roundtrip
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

uid='Validator R14 Self <r14-self@example.invalid>'

# default future-default => primary cert + encryption subkey; suitable for -e.
gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --quick-generate-key "$uid" default default 1d >/dev/null 2>&1

printf 'r14 encrypt-to-self payload line 1\nr14 line 2\n' >"$tmpdir/plain.txt"

gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --trust-model always --encrypt -r "$uid" \
  -o "$tmpdir/cipher.gpg" "$tmpdir/plain.txt" >/dev/null 2>&1

gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --decrypt -o "$tmpdir/round.txt" "$tmpdir/cipher.gpg" >/dev/null 2>&1

cmp "$tmpdir/plain.txt" "$tmpdir/round.txt"
