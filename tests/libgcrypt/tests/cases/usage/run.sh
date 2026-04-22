#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
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

case "$case_id" in
  usage-gpg-version-libgcrypt)
    gpg --version >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'libgcrypt'
    ;;
  usage-gpg-print-md)
    printf 'digest payload\n' >"$tmpdir/plain.txt"
    gpg --print-md SHA256 "$tmpdir/plain.txt" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'DFFEA5CC'
    ;;
  usage-gpg-symmetric-roundtrip)
    printf 'secret payload\n' >"$tmpdir/plain.txt"
    "${gpg_batch[@]}" --passphrase "$passphrase" --symmetric --cipher-algo AES256 -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"
    "${gpg_batch[@]}" --passphrase "$passphrase" --decrypt -o "$tmpdir/out" "$tmpdir/plain.gpg"
    validator_assert_contains "$tmpdir/out" 'secret payload'
    ;;
  usage-gpg-symmetric-armor)
    printf 'armored payload\n' >"$tmpdir/plain.txt"
    "${gpg_batch[@]}" --armor --passphrase "$passphrase" --symmetric -o "$tmpdir/plain.asc" "$tmpdir/plain.txt"
    validator_assert_contains "$tmpdir/plain.asc" 'BEGIN PGP MESSAGE'
    "${gpg_batch[@]}" --passphrase "$passphrase" --decrypt -o "$tmpdir/out" "$tmpdir/plain.asc"
    validator_assert_contains "$tmpdir/out" 'armored payload'
    ;;
  usage-gpg-detached-sign-verify)
    make_signing_key
    printf 'signed payload\n' >"$tmpdir/plain.txt"
    "${gpg_batch[@]}" --armor --detach-sign -o "$tmpdir/plain.asc" "$tmpdir/plain.txt"
    gpg --verify "$tmpdir/plain.asc" "$tmpdir/plain.txt" >"$tmpdir/out" 2>&1
    validator_assert_contains "$tmpdir/out" 'Good signature'
    ;;
  usage-gpg-clearsign-verify)
    make_signing_key
    printf 'clear signed payload\n' >"$tmpdir/plain.txt"
    "${gpg_batch[@]}" --clearsign -o "$tmpdir/plain.asc" "$tmpdir/plain.txt"
    gpg --verify "$tmpdir/plain.asc" >"$tmpdir/out" 2>&1
    validator_assert_contains "$tmpdir/out" 'Good signature'
    ;;
  usage-gpg-export-import-key)
    make_signing_key
    gpg --armor --export "$uid" >"$tmpdir/pub.asc"
    export GNUPGHOME="$tmpdir/imported"
    mkdir -p "$GNUPGHOME"
    chmod 700 "$GNUPGHOME"
    gpg --batch --import "$tmpdir/pub.asc" >"$tmpdir/out" 2>&1
    validator_assert_contains "$tmpdir/out" 'imported'
    ;;
  usage-gpg-recipient-encrypt)
    make_encryption_key
    printf 'recipient payload\n' >"$tmpdir/plain.txt"
    "${gpg_batch[@]}" --trust-model always --encrypt -r "$uid" -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"
    "${gpg_batch[@]}" --decrypt -o "$tmpdir/out" "$tmpdir/plain.gpg"
    validator_assert_contains "$tmpdir/out" 'recipient payload'
    ;;
  usage-gpg-list-packets)
    printf 'packet payload\n' >"$tmpdir/plain.txt"
    "${gpg_batch[@]}" --passphrase "$passphrase" --symmetric -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"
    "${gpg_batch[@]}" --passphrase "$passphrase" --list-packets "$tmpdir/plain.gpg" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'symkey enc packet'
    ;;
  usage-gpg-list-keys)
    make_signing_key
    gpg --list-keys "$uid" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Validator User'
    ;;
  *)
    printf 'unknown libgcrypt usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
