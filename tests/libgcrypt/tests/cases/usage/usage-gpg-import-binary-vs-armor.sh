#!/usr/bin/env bash
# @testcase: usage-gpg-import-binary-vs-armor
# @title: gpg imports binary and armored exports of the same key
# @description: Exports a generated public key in both binary and ASCII-armored form, imports each into separate fresh keyrings, and verifies the resulting fingerprints (and uids) match exactly between the two import paths.
# @timeout: 240
# @tags: usage, gpg, keyring
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-import-binary-vs-armor"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

source_home="$tmpdir/source_home"
bin_home="$tmpdir/bin_home"
asc_home="$tmpdir/asc_home"
mkdir -p "$source_home" "$bin_home" "$asc_home"
chmod 700 "$source_home" "$bin_home" "$asc_home"

uid='Validator ImportBin <validator-import-bin@example.invalid>'

GNUPGHOME="$source_home" gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --quick-generate-key "$uid" default default 1d >/dev/null 2>&1

GNUPGHOME="$source_home" gpg --export "$uid" >"$tmpdir/key.bin"
GNUPGHOME="$source_home" gpg --armor --export "$uid" >"$tmpdir/key.asc"

[[ -s "$tmpdir/key.bin" ]] || { printf 'binary export empty\n' >&2; exit 1; }
validator_assert_contains "$tmpdir/key.asc" 'BEGIN PGP PUBLIC KEY BLOCK'

GNUPGHOME="$bin_home" gpg --batch --import "$tmpdir/key.bin" >"$tmpdir/bin.import" 2>&1
GNUPGHOME="$asc_home" gpg --batch --import "$tmpdir/key.asc" >"$tmpdir/asc.import" 2>&1
validator_assert_contains "$tmpdir/bin.import" 'imported'
validator_assert_contains "$tmpdir/asc.import" 'imported'

GNUPGHOME="$bin_home" gpg --with-colons --fingerprint "$uid" \
  | awk -F: '$1=="fpr" {print $10; exit}' >"$tmpdir/fpr.bin"
GNUPGHOME="$asc_home" gpg --with-colons --fingerprint "$uid" \
  | awk -F: '$1=="fpr" {print $10; exit}' >"$tmpdir/fpr.asc"

[[ -s "$tmpdir/fpr.bin" && -s "$tmpdir/fpr.asc" ]] || {
  printf 'failed to extract fingerprints\n' >&2
  exit 1
}
diff "$tmpdir/fpr.bin" "$tmpdir/fpr.asc" >/dev/null || {
  printf 'binary and armored imports yielded different fingerprints\n' >&2
  printf 'bin: '; cat "$tmpdir/fpr.bin" >&2
  printf 'asc: '; cat "$tmpdir/fpr.asc" >&2
  exit 1
}

GNUPGHOME="$bin_home" gpg --list-keys "$uid" >"$tmpdir/list.bin"
GNUPGHOME="$asc_home" gpg --list-keys "$uid" >"$tmpdir/list.asc"
validator_assert_contains "$tmpdir/list.bin" 'validator-import-bin@example.invalid'
validator_assert_contains "$tmpdir/list.asc" 'validator-import-bin@example.invalid'
