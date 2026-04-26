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
uid='Validator Further <validator-further@example.invalid>'

make_signing_key() {
  "${gpg_batch[@]}" --passphrase '' --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1
}

case "$case_id" in
  usage-gpg-print-md-md5)
    printf 'digest payload\n' >"$tmpdir/plain.txt"
    gpg --print-md MD5 "$tmpdir/plain.txt" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'plain.txt:'
    grep -Eq '[0-9A-F]{2} [0-9A-F]{2}' "$tmpdir/out"
    ;;
  usage-gpg-symmetric-3des)
    printf '3des payload\n' >"$tmpdir/plain.txt"
    "${gpg_batch[@]}" --allow-old-cipher-algos --passphrase "$passphrase" --symmetric --cipher-algo 3DES -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"
    "${gpg_batch[@]}" --passphrase "$passphrase" --decrypt -o "$tmpdir/out" "$tmpdir/plain.gpg"
    validator_assert_contains "$tmpdir/out" '3des payload'
    ;;
  usage-gpg-list-packets-symmetric-aes256)
    printf 'packet payload\n' >"$tmpdir/plain.txt"
    "${gpg_batch[@]}" --passphrase "$passphrase" --symmetric --cipher-algo AES256 -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"
    "${gpg_batch[@]}" --passphrase "$passphrase" --list-packets "$tmpdir/plain.gpg" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'encrypted data packet'
    ;;
  usage-gpg-verify-detached-status-fd)
    make_signing_key
    printf 'status payload\n' >"$tmpdir/plain.txt"
    "${gpg_batch[@]}" --detach-sign -o "$tmpdir/plain.sig" "$tmpdir/plain.txt"
    gpg --status-fd 1 --verify "$tmpdir/plain.sig" "$tmpdir/plain.txt" >"$tmpdir/out" 2>/dev/null
    validator_assert_contains "$tmpdir/out" 'GOODSIG'
    ;;
  usage-gpg-export-public-minimal)
    make_signing_key
    gpg --armor --export-options export-minimal --export "$uid" >"$tmpdir/public.asc"
    validator_assert_contains "$tmpdir/public.asc" 'BEGIN PGP PUBLIC KEY BLOCK'
    ;;
  usage-gpg-import-show-only)
    make_signing_key
    gpg --armor --export "$uid" >"$tmpdir/public.asc"
    other_home="$tmpdir/other"
    mkdir -p "$other_home"
    chmod 700 "$other_home"
    GNUPGHOME="$other_home" gpg --import-options show-only --dry-run --import "$tmpdir/public.asc" >"$tmpdir/out" 2>&1
    validator_assert_contains "$tmpdir/out" 'pub'
    ;;
  usage-gpg-list-secret-keys-keygrip)
    make_signing_key
    gpg --with-keygrip --list-secret-keys "$uid" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Keygrip'
    ;;
  usage-gpg-symmetric-zlib-compress)
    printf 'zlib payload\n' >"$tmpdir/plain.txt"
    "${gpg_batch[@]}" --passphrase "$passphrase" --compress-algo ZLIB --symmetric -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"
    "${gpg_batch[@]}" --passphrase "$passphrase" --decrypt -o "$tmpdir/out" "$tmpdir/plain.gpg"
    validator_assert_contains "$tmpdir/out" 'zlib payload'
    ;;
  usage-gpg-symmetric-bzip2-compress)
    printf 'bzip2 payload\n' >"$tmpdir/plain.txt"
    "${gpg_batch[@]}" --passphrase "$passphrase" --compress-algo BZIP2 --symmetric -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"
    "${gpg_batch[@]}" --passphrase "$passphrase" --decrypt -o "$tmpdir/out" "$tmpdir/plain.gpg"
    validator_assert_contains "$tmpdir/out" 'bzip2 payload'
    ;;
  usage-gpg-decrypt-clearsigned-message)
    make_signing_key
    printf 'clear payload\n' >"$tmpdir/plain.txt"
    "${gpg_batch[@]}" --clearsign -o "$tmpdir/plain.asc" "$tmpdir/plain.txt"
    gpg --decrypt "$tmpdir/plain.asc" >"$tmpdir/out" 2>/dev/null
    validator_assert_contains "$tmpdir/out" 'clear payload'
    ;;
  *)
    printf 'unknown libgcrypt further usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
