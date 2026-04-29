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
uid='Validator Batch11 <validator-batch11@example.invalid>'

make_signing_key() {
  "${gpg_batch[@]}" --passphrase '' --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1
}

make_encryption_key() {
  "${gpg_batch[@]}" --passphrase '' --quick-generate-key "$uid" rsa2048 encrypt 1d >/dev/null 2>&1
}

case "$case_id" in
  usage-gpg-print-md-sha1-batch11)
    printf 'sha1 payload\n' >"$tmpdir/plain.txt"
    gpg --print-md SHA1 "$tmpdir/plain.txt" >"$tmpdir/out"
    test "$(wc -c <"$tmpdir/out")" -gt 20
    ;;
  usage-gpg-print-md-md5-batch11)
    printf 'md5 payload\n' >"$tmpdir/plain.txt"
    gpg --print-md MD5 "$tmpdir/plain.txt" >"$tmpdir/out"
    test "$(wc -c <"$tmpdir/out")" -gt 20
    ;;
  usage-gpg-gen-random-length-batch11)
    gpg --gen-random 1 16 >"$tmpdir/random.bin"
    test "$(wc -c <"$tmpdir/random.bin")" -eq 16
    ;;
  usage-gpg-enarmor-dearmor-batch11)
    printf 'armor payload\n' >"$tmpdir/plain.bin"
    gpg --enarmor <"$tmpdir/plain.bin" >"$tmpdir/plain.asc"
    gpg --dearmor <"$tmpdir/plain.asc" >"$tmpdir/restored.bin"
    cmp "$tmpdir/plain.bin" "$tmpdir/restored.bin"
    ;;
  usage-gpg-symmetric-aes128-batch11)
    printf 'aes128 payload\n' >"$tmpdir/plain.txt"
    "${gpg_batch[@]}" --cipher-algo AES128 --passphrase "$passphrase" --symmetric -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"
    "${gpg_batch[@]}" --passphrase "$passphrase" --decrypt -o "$tmpdir/out" "$tmpdir/plain.gpg"
    validator_assert_contains "$tmpdir/out" 'aes128 payload'
    ;;
  usage-gpg-symmetric-aes192-batch11)
    printf 'aes192 payload\n' >"$tmpdir/plain.txt"
    "${gpg_batch[@]}" --cipher-algo AES192 --passphrase "$passphrase" --symmetric -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"
    "${gpg_batch[@]}" --passphrase "$passphrase" --decrypt -o "$tmpdir/out" "$tmpdir/plain.gpg"
    validator_assert_contains "$tmpdir/out" 'aes192 payload'
    ;;
  usage-gpg-detached-binary-sign-batch11)
    make_signing_key
    printf 'binary signature payload\n' >"$tmpdir/plain.txt"
    "${gpg_batch[@]}" --detach-sign -o "$tmpdir/plain.sig" "$tmpdir/plain.txt"
    gpg --verify "$tmpdir/plain.sig" "$tmpdir/plain.txt" >"$tmpdir/out" 2>&1
    validator_assert_contains "$tmpdir/out" 'Good signature'
    ;;
  usage-gpg-recipient-armor-encrypt-batch11)
    make_encryption_key
    printf 'armored recipient payload\n' >"$tmpdir/plain.txt"
    "${gpg_batch[@]}" --armor --trust-model always --encrypt -r "$uid" -o "$tmpdir/plain.asc" "$tmpdir/plain.txt"
    validator_assert_contains "$tmpdir/plain.asc" 'BEGIN PGP MESSAGE'
    "${gpg_batch[@]}" --decrypt -o "$tmpdir/out" "$tmpdir/plain.asc"
    validator_assert_contains "$tmpdir/out" 'armored recipient payload'
    ;;
  usage-gpg-symmetric-list-packets-cipher-batch11)
    printf 'packet cipher payload\n' >"$tmpdir/plain.txt"
    "${gpg_batch[@]}" --passphrase "$passphrase" --symmetric -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"
    "${gpg_batch[@]}" --passphrase "$passphrase" --list-packets "$tmpdir/plain.gpg" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'encrypted data packet'
    ;;
  usage-gpg-public-key-packet-batch11)
    make_signing_key
    gpg --export "$uid" >"$tmpdir/pub.gpg"
    gpg --list-packets "$tmpdir/pub.gpg" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'public key packet'
    ;;
  *)
    printf 'unknown libgcrypt eleventh-batch usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
