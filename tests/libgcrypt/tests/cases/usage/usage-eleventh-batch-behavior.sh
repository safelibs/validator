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
  usage-gpg-list-config-ciphername-batch11)
    gpg --with-colons --list-config >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'cfg:ciphername:'
    validator_assert_contains "$tmpdir/out" 'TWOFISH'
    ;;
  usage-gpg-list-config-digestname-batch11)
    gpg --with-colons --list-config >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'cfg:digestname:'
    validator_assert_contains "$tmpdir/out" 'SHA512'
    ;;
  usage-gpg-gen-random-length-batch11)
    gpg --gen-random 1 16 >"$tmpdir/random.bin"
    test "$(wc -c <"$tmpdir/random.bin")" -eq 16
    ;;
  usage-gpg-list-config-compressname-batch11)
    gpg --with-colons --list-config >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'cfg:compressname:'
    validator_assert_contains "$tmpdir/out" 'BZIP2'
    ;;
  usage-gpg-symmetric-twofish-batch11)
    printf 'twofish payload\n' >"$tmpdir/plain.txt"
    "${gpg_batch[@]}" --cipher-algo TWOFISH --passphrase "$passphrase" --symmetric -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"
    "${gpg_batch[@]}" --passphrase "$passphrase" --decrypt -o "$tmpdir/out" "$tmpdir/plain.gpg"
    validator_assert_contains "$tmpdir/out" 'twofish payload'
    ;;
  usage-gpg-symmetric-camellia256-batch11)
    printf 'camellia payload\n' >"$tmpdir/plain.txt"
    "${gpg_batch[@]}" --cipher-algo CAMELLIA256 --passphrase "$passphrase" --symmetric -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"
    "${gpg_batch[@]}" --passphrase "$passphrase" --decrypt -o "$tmpdir/out" "$tmpdir/plain.gpg"
    validator_assert_contains "$tmpdir/out" 'camellia payload'
    ;;
  usage-gpg-clearsign-verify-batch11)
    make_signing_key
    printf 'clear signature payload\n' >"$tmpdir/plain.txt"
    "${gpg_batch[@]}" --clearsign -o "$tmpdir/plain.asc" "$tmpdir/plain.txt"
    gpg --verify "$tmpdir/plain.asc" >"$tmpdir/out" 2>&1
    validator_assert_contains "$tmpdir/out" 'Good signature'
    ;;
  usage-gpg-hidden-recipient-encrypt-batch11)
    make_encryption_key
    printf 'hidden recipient payload\n' >"$tmpdir/plain.txt"
    "${gpg_batch[@]}" --trust-model always --hidden-recipient "$uid" --encrypt -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"
    "${gpg_batch[@]}" --decrypt -o "$tmpdir/out" "$tmpdir/plain.gpg"
    validator_assert_contains "$tmpdir/out" 'hidden recipient payload'
    ;;
  usage-gpg-store-compressed-packet-batch11)
    for _ in $(seq 1 40); do
      printf 'compressed packet payload\n'
    done >"$tmpdir/plain.txt"
    "${gpg_batch[@]}" --compress-algo ZIP --store -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"
    gpg --list-packets "$tmpdir/plain.gpg" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'compressed packet'
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
