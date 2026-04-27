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
  usage-gpg-print-md-sha384-hex)
    printf 'sha384 payload\n' >"$tmpdir/plain.txt"
    gpg --print-md SHA384 "$tmpdir/plain.txt" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'plain.txt:'
    groups=$(grep -Eo '[0-9A-F]{4}' "$tmpdir/out" | wc -l)
    test "$groups" -ge 20
    ;;
  usage-gpg-print-md-sha256-hex)
    printf 'sha256 payload\n' >"$tmpdir/plain.txt"
    gpg --print-md SHA256 "$tmpdir/plain.txt" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'plain.txt:'
    groups=$(grep -Eo '[0-9A-F]{4}' "$tmpdir/out" | wc -l)
    test "$groups" -ge 14
    ;;
  usage-gpg-symmetric-aes256-roundtrip)
    printf 'aes256 payload\n' >"$tmpdir/plain.txt"
    "${gpg_batch[@]}" --passphrase "$passphrase" --symmetric --cipher-algo AES256 -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"
    "${gpg_batch[@]}" --passphrase "$passphrase" --decrypt -o "$tmpdir/out" "$tmpdir/plain.gpg"
    validator_assert_contains "$tmpdir/out" 'aes256 payload'
    ;;
  usage-gpg-symmetric-armor-output)
    printf 'symmetric armor body\n' >"$tmpdir/plain.txt"
    "${gpg_batch[@]}" --armor --passphrase "$passphrase" --symmetric -o "$tmpdir/plain.asc" "$tmpdir/plain.txt"
    validator_assert_contains "$tmpdir/plain.asc" 'BEGIN PGP MESSAGE'
    "${gpg_batch[@]}" --passphrase "$passphrase" --decrypt -o "$tmpdir/out" "$tmpdir/plain.asc"
    validator_assert_contains "$tmpdir/out" 'symmetric armor body'
    ;;
  usage-gpg-clearsign-roundtrip-output)
    make_signing_key
    printf 'clearsign body line\n' >"$tmpdir/plain.txt"
    "${gpg_batch[@]}" --clearsign -o "$tmpdir/plain.asc" "$tmpdir/plain.txt"
    validator_assert_contains "$tmpdir/plain.asc" 'BEGIN PGP SIGNED MESSAGE'
    validator_assert_contains "$tmpdir/plain.asc" 'clearsign body line'
    ;;
  usage-gpg-export-armor-block)
    make_signing_key
    gpg --armor --export "$uid" >"$tmpdir/pub.asc"
    validator_assert_contains "$tmpdir/pub.asc" 'BEGIN PGP PUBLIC KEY BLOCK'
    validator_assert_contains "$tmpdir/pub.asc" 'END PGP PUBLIC KEY BLOCK'
    ;;
  usage-gpg-list-keys-uid)
    make_signing_key
    gpg --list-keys "$uid" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Validator User'
    ;;
  usage-gpg-gen-random-zero-bytes)
    gpg --gen-random 0 32 >"$tmpdir/random.bin"
    bytes=$(wc -c <"$tmpdir/random.bin")
    test "$bytes" -eq 32
    ;;
  usage-gpg-symmetric-stdin-armor)
    printf 'stdin armor payload\n' | "${gpg_batch[@]}" --armor --passphrase "$passphrase" --symmetric -o "$tmpdir/plain.asc"
    validator_assert_contains "$tmpdir/plain.asc" 'BEGIN PGP MESSAGE'
    "${gpg_batch[@]}" --passphrase "$passphrase" --decrypt -o "$tmpdir/out" "$tmpdir/plain.asc"
    validator_assert_contains "$tmpdir/out" 'stdin armor payload'
    ;;
  usage-gpg-list-packets-clearsign)
    make_signing_key
    printf 'list packets clearsign\n' >"$tmpdir/plain.txt"
    "${gpg_batch[@]}" --sign --armor -o "$tmpdir/plain.asc" "$tmpdir/plain.txt"
    "${gpg_batch[@]}" --list-packets "$tmpdir/plain.asc" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'signature packet'
    ;;
  *)
    printf 'unknown libgcrypt tenth-batch usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
