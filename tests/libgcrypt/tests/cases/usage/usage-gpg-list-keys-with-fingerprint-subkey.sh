#!/usr/bin/env bash
# @testcase: usage-gpg-list-keys-with-fingerprint-subkey
# @title: gpg --list-keys --with-fingerprint shows subkey fingerprint
# @description: Generates a primary+subkey pair (default ed25519/cv25519) and asserts that gpg --list-keys --with-fingerprint --with-fingerprint emits the spaced fingerprint for both the primary key and the encryption subkey.
# @timeout: 240
# @tags: usage, gpg, keys, listing
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-list-keys-with-fingerprint-subkey"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
uid='Validator FprSubkey <validator-fprsubkey@example.invalid>'

# default+default produces a primary signing key plus an encryption subkey.
"${gpg_batch[@]}" --passphrase '' \
  --quick-generate-key "$uid" default default 1d >/dev/null 2>&1

# Pull the primary and subkey fingerprints in machine-readable form.
mapfile -t fprs < <(gpg --with-colons --fingerprint "$uid" \
  | awk -F: '$1 == "fpr" {print $10}')

if (( ${#fprs[@]} < 2 )); then
  printf 'expected at least 2 fingerprints, got %d\n' "${#fprs[@]}" >&2
  gpg --with-colons --fingerprint "$uid" >&2
  exit 1
fi

primary_fpr=${fprs[0]}
subkey_fpr=${fprs[1]}
test "${#primary_fpr}" = "40"
test "${#subkey_fpr}" = "40"
test "$primary_fpr" != "$subkey_fpr"

# Build the spaced human-readable form gpg prints with --with-fingerprint:
# 10 groups of 4 hex digits, with a double-space between groups 5 and 6.
spaced_fpr() {
  local fpr=$1 out=""
  local i
  for (( i = 0; i < 40; i += 4 )); do
    [[ -n "$out" ]] && out+=" "
    [[ "$i" -eq 20 ]] && out+=" "
    out+="${fpr:$i:4}"
  done
  printf '%s' "$out"
}

primary_spaced=$(spaced_fpr "$primary_fpr")
subkey_spaced=$(spaced_fpr "$subkey_fpr")

# --with-fingerprint must be repeated to print subkey fingerprints in
# spaced human-readable form alongside the primary fingerprint.
gpg --list-keys --with-fingerprint --with-fingerprint "$uid" \
  >"$tmpdir/list.out" 2>&1

validator_assert_contains "$tmpdir/list.out" "$primary_spaced"
validator_assert_contains "$tmpdir/list.out" "$subkey_spaced"
