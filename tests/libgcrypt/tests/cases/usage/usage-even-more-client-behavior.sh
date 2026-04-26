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
uid='Validator Even More <validator-even-more@example.invalid>'

make_default_key() {
  "${gpg_batch[@]}" --passphrase '' --quick-generate-key "$uid" default default 1d >/dev/null 2>&1
}

case "$case_id" in
  usage-gpg-clearsign-verify-status)
    make_default_key
    printf 'clearsign payload\n' >"$tmpdir/plain.txt"
    "${gpg_batch[@]}" --clearsign -o "$tmpdir/plain.asc" "$tmpdir/plain.txt"
    gpg --verify "$tmpdir/plain.asc" >"$tmpdir/out" 2>&1 || true
    validator_assert_contains "$tmpdir/out" 'Good signature'
    ;;
  usage-gpg-symmetric-armored-message)
    printf 'armor payload\n' >"$tmpdir/plain.txt"
    "${gpg_batch[@]}" --passphrase "$passphrase" --armor --symmetric -o "$tmpdir/plain.asc" "$tmpdir/plain.txt"
    validator_assert_contains "$tmpdir/plain.asc" 'BEGIN PGP MESSAGE'
    "${gpg_batch[@]}" --passphrase "$passphrase" --decrypt -o "$tmpdir/out.txt" "$tmpdir/plain.asc"
    validator_assert_contains "$tmpdir/out.txt" 'armor payload'
    ;;
  usage-gpg-recipient-encrypt-decrypt-output)
    make_default_key
    printf 'recipient payload\n' >"$tmpdir/plain.txt"
    "${gpg_batch[@]}" --trust-model always --encrypt -r "$uid" -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"
    "${gpg_batch[@]}" --decrypt -o "$tmpdir/out.txt" "$tmpdir/plain.gpg"
    validator_assert_contains "$tmpdir/out.txt" 'recipient payload'
    ;;
  usage-gpg-armored-message-header-only)
    make_default_key
    printf 'armored recipient payload\n' >"$tmpdir/plain.txt"
    "${gpg_batch[@]}" --trust-model always --armor --encrypt -r "$uid" -o "$tmpdir/plain.asc" "$tmpdir/plain.txt"
    validator_assert_contains "$tmpdir/plain.asc" 'BEGIN PGP MESSAGE'
    ;;
  usage-gpg-list-packets-binary-detached)
    make_default_key
    printf 'binary signature payload\n' >"$tmpdir/plain.txt"
    "${gpg_batch[@]}" --detach-sign -o "$tmpdir/plain.sig" "$tmpdir/plain.txt"
    gpg --list-packets "$tmpdir/plain.sig" >"$tmpdir/out" 2>&1 || true
    validator_assert_contains "$tmpdir/out" 'signature packet'
    ;;
  usage-gpg-verify-status-stream)
    make_default_key
    printf 'status payload\n' >"$tmpdir/plain.txt"
    "${gpg_batch[@]}" --detach-sign -o "$tmpdir/plain.sig" "$tmpdir/plain.txt"
    gpg --status-fd 1 --verify "$tmpdir/plain.sig" "$tmpdir/plain.txt" >"$tmpdir/out" 2>/dev/null || true
    validator_assert_contains "$tmpdir/out" 'GOODSIG'
    validator_assert_contains "$tmpdir/out" 'VALIDSIG'
    ;;
  usage-gpg-sign-file-roundtrip)
    make_default_key
    printf 'signed file payload\n' >"$tmpdir/plain.txt"
    "${gpg_batch[@]}" --sign -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"
    "${gpg_batch[@]}" --decrypt "$tmpdir/plain.gpg" >"$tmpdir/out.txt"
    validator_assert_contains "$tmpdir/out.txt" 'signed file payload'
    ;;
  usage-gpg-encrypt-decrypt-stdout-pipe)
    make_default_key
    printf 'stdout decrypt payload\n' >"$tmpdir/plain.txt"
    "${gpg_batch[@]}" --trust-model always --encrypt -r "$uid" -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"
    "${gpg_batch[@]}" --decrypt "$tmpdir/plain.gpg" >"$tmpdir/out.txt"
    validator_assert_contains "$tmpdir/out.txt" 'stdout decrypt payload'
    ;;
  usage-gpg-ownertrust-export-check)
    make_default_key
    fingerprint=$(gpg --with-colons --fingerprint "$uid" | awk -F: '$1 == "fpr" {print $10; exit}')
    printf '%s:6:\n' "$fingerprint" | gpg --import-ownertrust >"$tmpdir/import.out" 2>&1
    gpg --export-ownertrust >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" "$fingerprint"
    ;;
  usage-gpg-import-public-key-listing)
    make_default_key
    gpg --armor --export "$uid" >"$tmpdir/public.asc"
    other_home="$tmpdir/other"
    mkdir -p "$other_home"
    chmod 700 "$other_home"
    GNUPGHOME="$other_home" gpg --batch --import "$tmpdir/public.asc" >"$tmpdir/import.out" 2>&1
    GNUPGHOME="$other_home" gpg --list-keys "$uid" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Validator Even More'
    ;;
  *)
    printf 'unknown libgcrypt even-more usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
