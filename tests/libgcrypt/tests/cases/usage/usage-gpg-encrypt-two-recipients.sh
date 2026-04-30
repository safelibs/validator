#!/usr/bin/env bash
# @testcase: usage-gpg-encrypt-two-recipients
# @title: gpg encrypt for two recipients then decrypt
# @description: Generates two distinct keypairs, encrypts a payload addressed to both, asserts the ciphertext contains two pubkey-enc packets via --list-packets, and decrypts the message in a fresh keyring that holds only the second recipient.
# @timeout: 240
# @tags: usage, gpg, crypto
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-encrypt-two-recipients"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

home_a="$tmpdir/home_a"
home_b="$tmpdir/home_b"
home_combined="$tmpdir/home_combined"
home_b_only="$tmpdir/home_b_only"
mkdir -p "$home_a" "$home_b" "$home_combined" "$home_b_only"
chmod 700 "$home_a" "$home_b" "$home_combined" "$home_b_only"

uid_a='Validator A <validator-a@example.invalid>'
uid_b='Validator B <validator-b@example.invalid>'

GNUPGHOME="$home_a" gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --quick-generate-key "$uid_a" default default 1d >/dev/null 2>&1
GNUPGHOME="$home_b" gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --quick-generate-key "$uid_b" default default 1d >/dev/null 2>&1

GNUPGHOME="$home_a" gpg --export "$uid_a" >"$tmpdir/a.pub.pgp"
GNUPGHOME="$home_b" gpg --export "$uid_b" >"$tmpdir/b.pub.pgp"
GNUPGHOME="$home_b" gpg --export-secret-keys --batch --pinentry-mode loopback --passphrase '' "$uid_b" >"$tmpdir/b.sec.pgp"

GNUPGHOME="$home_combined" gpg --batch --import "$tmpdir/a.pub.pgp" >/dev/null 2>&1
GNUPGHOME="$home_combined" gpg --batch --import "$tmpdir/b.pub.pgp" >/dev/null 2>&1

printf 'two recipient payload\n' >"$tmpdir/plain.txt"
GNUPGHOME="$home_combined" gpg --batch --yes --pinentry-mode loopback --trust-model always \
  --encrypt -r "$uid_a" -r "$uid_b" -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"

# --list-packets can exit non-zero when the keyring has no matching secret
# key (gpg attempts decryption); we only care about the parsed packets.
GNUPGHOME="$home_combined" gpg --list-packets "$tmpdir/plain.gpg" >"$tmpdir/packets" 2>&1 || true
pubkey_count=$(grep -c ':pubkey enc packet:' "$tmpdir/packets" || true)
[[ "$pubkey_count" == "2" ]] || {
  printf 'expected 2 pubkey enc packets, got %s\n' "$pubkey_count" >&2
  cat "$tmpdir/packets" >&2
  exit 1
}

GNUPGHOME="$home_b_only" gpg --batch --import "$tmpdir/b.sec.pgp" >/dev/null 2>&1
GNUPGHOME="$home_b_only" gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --decrypt -o "$tmpdir/out.txt" "$tmpdir/plain.gpg"
validator_assert_contains "$tmpdir/out.txt" 'two recipient payload'
