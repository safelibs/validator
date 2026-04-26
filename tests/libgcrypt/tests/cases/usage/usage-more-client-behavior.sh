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
uid='Validator More <validator-more@example.invalid>'

make_signing_key() {
  "${gpg_batch[@]}" --passphrase '' --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1
}

case "$case_id" in
  usage-gpg-print-md-ripemd160)
    printf 'digest payload\n' >"$tmpdir/plain.txt"
    gpg --print-md RIPEMD160 "$tmpdir/plain.txt" >"$tmpdir/out"
    grep -Eq '[0-9A-F]{4}' "$tmpdir/out"
    ;;
  usage-gpg-enarmor-roundtrip)
    printf 'armored file payload\n' >"$tmpdir/plain.bin"
    gpg --enarmor <"$tmpdir/plain.bin" >"$tmpdir/plain.asc"
    validator_assert_contains "$tmpdir/plain.asc" 'BEGIN PGP ARMORED FILE'
    gpg --dearmor -o "$tmpdir/out.bin" "$tmpdir/plain.asc"
    cmp "$tmpdir/plain.bin" "$tmpdir/out.bin"
    ;;
  usage-gpg-symmetric-passphrase-file)
    printf '%s\n' "$passphrase" >"$tmpdir/passphrase.txt"
    printf 'passphrase file payload\n' >"$tmpdir/plain.txt"
    "${gpg_batch[@]}" --passphrase-file "$tmpdir/passphrase.txt" --symmetric -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"
    "${gpg_batch[@]}" --passphrase-file "$tmpdir/passphrase.txt" --decrypt -o "$tmpdir/out.txt" "$tmpdir/plain.gpg"
    validator_assert_contains "$tmpdir/out.txt" 'passphrase file payload'
    ;;
  usage-gpg-symmetric-stdin)
    printf 'stdin payload\n' | "${gpg_batch[@]}" --passphrase "$passphrase" --symmetric -o "$tmpdir/stdin.gpg"
    "${gpg_batch[@]}" --passphrase "$passphrase" --decrypt -o "$tmpdir/out.txt" "$tmpdir/stdin.gpg"
    validator_assert_contains "$tmpdir/out.txt" 'stdin payload'
    ;;
  usage-gpg-decrypt-stdout)
    printf 'stdout decrypt payload\n' >"$tmpdir/plain.txt"
    "${gpg_batch[@]}" --passphrase "$passphrase" --symmetric -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"
    "${gpg_batch[@]}" --passphrase "$passphrase" --decrypt "$tmpdir/plain.gpg" >"$tmpdir/out.txt"
    validator_assert_contains "$tmpdir/out.txt" 'stdout decrypt payload'
    ;;
  usage-gpg-list-packets-armor)
    make_signing_key
    printf 'packet payload\n' >"$tmpdir/plain.txt"
    "${gpg_batch[@]}" --armor --detach-sign -o "$tmpdir/plain.asc" "$tmpdir/plain.txt"
    gpg --list-packets "$tmpdir/plain.asc" >"$tmpdir/out" 2>&1 || true
    validator_assert_contains "$tmpdir/out" 'signature packet'
    ;;
  usage-gpg-export-ownertrust)
    make_signing_key
    fingerprint=$(gpg --with-colons --fingerprint "$uid" | awk -F: '$1 == "fpr" {print $10; exit}')
    printf '%s:6:\n' "$fingerprint" | gpg --import-ownertrust >"$tmpdir/import.out" 2>&1
    gpg --export-ownertrust >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" "$fingerprint"
    ;;
  usage-gpg-with-colons-fingerprint)
    make_signing_key
    gpg --with-colons --fingerprint "$uid" >"$tmpdir/out"
    awk -F: '$1 == "fpr" {print $10; exit}' "$tmpdir/out" >"$tmpdir/fpr"
    grep -Eq '^[0-9A-F]{40}$' "$tmpdir/fpr"
    ;;
  usage-gpg-import-secret-key)
    make_signing_key
    "${gpg_batch[@]}" --armor --export-secret-keys "$uid" >"$tmpdir/secret.asc"
    other_home="$tmpdir/other"
    mkdir -p "$other_home"
    chmod 700 "$other_home"
    GNUPGHOME="$other_home" gpg --batch --import "$tmpdir/secret.asc" >"$tmpdir/import.out" 2>&1
    GNUPGHOME="$other_home" gpg --list-secret-keys "$uid" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'sec'
    validator_assert_contains "$tmpdir/out" 'Validator More'
    ;;
  usage-gpg-list-secret-keys-colons)
    make_signing_key
    gpg --with-colons --list-secret-keys "$uid" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'sec'
    validator_assert_contains "$tmpdir/out" 'fpr'
    ;;
  *)
    printf 'unknown libgcrypt additional usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
