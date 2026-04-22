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
uid='Validator Extra <validator-extra@example.invalid>'

make_signing_key() {
  "${gpg_batch[@]}" --passphrase '' --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1
}

make_encryption_key() {
  "${gpg_batch[@]}" --passphrase '' --quick-generate-key "$uid" rsa2048 encrypt 1d >/dev/null 2>&1
}

case "$case_id" in
  usage-gpg-print-md-sha1)
    printf 'digest payload\n' >"$tmpdir/plain.txt"
    gpg --print-md SHA1 "$tmpdir/plain.txt" >"$tmpdir/out"
    grep -Eq '[0-9A-F]{4}' "$tmpdir/out"
    ;;
  usage-gpg-print-md-sha512)
    printf 'digest payload\n' >"$tmpdir/plain.txt"
    gpg --print-md SHA512 "$tmpdir/plain.txt" >"$tmpdir/out"
    grep -Eq '[0-9A-F]{4}' "$tmpdir/out"
    ;;
  usage-gpg-symmetric-aes128)
    printf 'aes128 payload\n' >"$tmpdir/plain.txt"
    "${gpg_batch[@]}" --passphrase "$passphrase" --symmetric --cipher-algo AES128 -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"
    "${gpg_batch[@]}" --passphrase "$passphrase" --decrypt -o "$tmpdir/out" "$tmpdir/plain.gpg"
    validator_assert_contains "$tmpdir/out" 'aes128 payload'
    ;;
  usage-gpg-symmetric-cast5)
    printf 'cast5 payload\n' >"$tmpdir/plain.txt"
    "${gpg_batch[@]}" --allow-old-cipher-algos --passphrase "$passphrase" --symmetric --cipher-algo CAST5 -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"
    "${gpg_batch[@]}" --passphrase "$passphrase" --decrypt -o "$tmpdir/out" "$tmpdir/plain.gpg"
    validator_assert_contains "$tmpdir/out" 'cast5 payload'
    ;;
  usage-gpg-detached-binary-sign)
    make_signing_key
    printf 'binary signed payload\n' >"$tmpdir/plain.txt"
    "${gpg_batch[@]}" --detach-sign -o "$tmpdir/plain.sig" "$tmpdir/plain.txt"
    gpg --verify "$tmpdir/plain.sig" "$tmpdir/plain.txt" >"$tmpdir/out" 2>&1
    validator_assert_contains "$tmpdir/out" 'Good signature'
    ;;
  usage-gpg-fingerprint-list)
    make_signing_key
    gpg --fingerprint "$uid" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Validator Extra'
    ;;
  usage-gpg-armor-recipient-encrypt)
    make_encryption_key
    printf 'armored recipient payload\n' >"$tmpdir/plain.txt"
    "${gpg_batch[@]}" --armor --trust-model always --encrypt -r "$uid" -o "$tmpdir/plain.asc" "$tmpdir/plain.txt"
    validator_assert_contains "$tmpdir/plain.asc" 'BEGIN PGP MESSAGE'
    "${gpg_batch[@]}" --decrypt -o "$tmpdir/out" "$tmpdir/plain.asc"
    validator_assert_contains "$tmpdir/out" 'armored recipient payload'
    ;;
  usage-gpg-import-ownertrust)
    make_signing_key
    fingerprint=$(gpg --with-colons --fingerprint "$uid" | awk -F: '$1 == "fpr" {print $10; exit}')
    printf '%s:6:\n' "$fingerprint" | gpg --import-ownertrust >"$tmpdir/out" 2>&1
    gpg --check-trustdb >"$tmpdir/trust" 2>&1 || true
    validator_assert_contains "$tmpdir/trust" 'trustdb'
    ;;
  usage-gpg-export-secret-key)
    make_signing_key
    "${gpg_batch[@]}" --armor --export-secret-keys "$uid" >"$tmpdir/secret.asc"
    validator_assert_contains "$tmpdir/secret.asc" 'BEGIN PGP PRIVATE KEY BLOCK'
    ;;
  usage-gpg-tampered-signature-reject)
    make_signing_key
    printf 'signed payload\n' >"$tmpdir/plain.txt"
    "${gpg_batch[@]}" --detach-sign -o "$tmpdir/plain.sig" "$tmpdir/plain.txt"
    printf 'tampered payload\n' >"$tmpdir/plain.txt"
    if gpg --verify "$tmpdir/plain.sig" "$tmpdir/plain.txt" >"$tmpdir/out" 2>&1; then
      printf 'tampered signature unexpectedly verified\n' >&2
      exit 1
    fi
    validator_assert_contains "$tmpdir/out" 'BAD signature'
    ;;
  *)
    printf 'unknown libgcrypt extra usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
