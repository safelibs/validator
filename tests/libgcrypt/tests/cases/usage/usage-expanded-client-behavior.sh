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
  usage-gpg-print-md-sha1-hex)
    printf 'digest payload\n' >"$tmpdir/plain.txt"
    gpg --print-md SHA1 "$tmpdir/plain.txt" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'plain.txt:'
    groups=$(grep -Eo '[0-9A-F]{4}' "$tmpdir/out" | wc -l)
    test "$groups" -ge 10
    ;;
  usage-gpg-print-md-ripemd160-hex)
    printf 'digest payload\n' >"$tmpdir/plain.txt"
    gpg --print-md RIPEMD160 "$tmpdir/plain.txt" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'plain.txt:'
    groups=$(grep -Eo '[0-9A-F]{4}' "$tmpdir/out" | wc -l)
    test "$groups" -ge 10
    ;;
  usage-gpg-enarmor-dearmor)
    printf 'enarmor payload\n' >"$tmpdir/plain.txt"
    gpg --enarmor <"$tmpdir/plain.txt" >"$tmpdir/plain.asc"
    gpg --dearmor <"$tmpdir/plain.asc" >"$tmpdir/plain.bin"
    cmp -s "$tmpdir/plain.txt" "$tmpdir/plain.bin"
    ;;
  usage-gpg-symmetric-aes128-roundtrip)
    printf 'aes128 payload\n' >"$tmpdir/plain.txt"
    "${gpg_batch[@]}" --passphrase "$passphrase" --symmetric --cipher-algo AES128 -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"
    "${gpg_batch[@]}" --passphrase "$passphrase" --decrypt -o "$tmpdir/out" "$tmpdir/plain.gpg"
    validator_assert_contains "$tmpdir/out" 'aes128 payload'
    ;;
  usage-gpg-symmetric-aes192-roundtrip)
    printf 'aes192 payload\n' >"$tmpdir/plain.txt"
    "${gpg_batch[@]}" --passphrase "$passphrase" --symmetric --cipher-algo AES192 -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"
    "${gpg_batch[@]}" --passphrase "$passphrase" --decrypt -o "$tmpdir/out" "$tmpdir/plain.gpg"
    validator_assert_contains "$tmpdir/out" 'aes192 payload'
    ;;
  usage-gpg-gen-random-bytes)
    gpg --gen-random 0 12 >"$tmpdir/random.bin"
    bytes=$(wc -c <"$tmpdir/random.bin")
    test "$bytes" -eq 12
    ;;
  usage-gpg-detached-sign-status-fd)
    make_signing_key
    printf 'status payload\n' >"$tmpdir/plain.txt"
    "${gpg_batch[@]}" --detach-sign -o "$tmpdir/plain.sig" "$tmpdir/plain.txt"
    gpg --status-fd 1 --verify "$tmpdir/plain.sig" "$tmpdir/plain.txt" >"$tmpdir/out" 2>&1
    validator_assert_contains "$tmpdir/out" '[GNUPG:] GOODSIG'
    ;;
  usage-gpg-list-packets-armored)
    printf 'armored packet payload\n' >"$tmpdir/plain.txt"
    "${gpg_batch[@]}" --armor --passphrase "$passphrase" --symmetric -o "$tmpdir/plain.asc" "$tmpdir/plain.txt"
    "${gpg_batch[@]}" --passphrase "$passphrase" --list-packets "$tmpdir/plain.asc" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'literal data packet'
    ;;
  usage-gpg-recipient-encrypt-armor)
    make_encryption_key
    printf 'recipient armor payload\n' >"$tmpdir/plain.txt"
    "${gpg_batch[@]}" --armor --trust-model always --encrypt -r "$uid" -o "$tmpdir/plain.asc" "$tmpdir/plain.txt"
    validator_assert_contains "$tmpdir/plain.asc" 'BEGIN PGP MESSAGE'
    "${gpg_batch[@]}" --decrypt -o "$tmpdir/out" "$tmpdir/plain.asc"
    validator_assert_contains "$tmpdir/out" 'recipient armor payload'
    ;;
  usage-gpg-list-secret-colons)
    make_signing_key
    gpg --with-colons --list-secret-keys "$uid" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'sec:'
    ;;
  *)
    printf 'unknown libgcrypt expanded usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
