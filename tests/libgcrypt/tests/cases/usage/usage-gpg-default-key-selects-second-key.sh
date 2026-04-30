#!/usr/bin/env bash
# @testcase: usage-gpg-default-key-selects-second-key
# @title: gpg --default-key selects between two keys
# @description: Generates two distinct signing keys in the same keyring and asserts gpg --default-key picks the explicitly named key for a detached signature (verified via the issuer fingerprint reported by gpg --list-packets).
# @timeout: 240
# @tags: usage, gpg, signing, keys
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-default-key-selects-second-key"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
uid_a='Validator DefaultKeyA <validator-defaultkey-a@example.invalid>'
uid_b='Validator DefaultKeyB <validator-defaultkey-b@example.invalid>'

# Two independent ed25519 signing keys in the same keyring.
"${gpg_batch[@]}" --passphrase '' \
  --quick-generate-key "$uid_a" ed25519 sign 1d >/dev/null 2>&1
"${gpg_batch[@]}" --passphrase '' \
  --quick-generate-key "$uid_b" ed25519 sign 1d >/dev/null 2>&1

fpr_a=$(gpg --with-colons --fingerprint "$uid_a" \
  | awk -F: '$1 == "fpr" {print $10; exit}')
fpr_b=$(gpg --with-colons --fingerprint "$uid_b" \
  | awk -F: '$1 == "fpr" {print $10; exit}')
test "${#fpr_a}" = "40"
test "${#fpr_b}" = "40"
test "$fpr_a" != "$fpr_b"

printf 'default-key payload\n' >"$tmpdir/plain.txt"

# Sign with --default-key pinned to key B; the issuer in the resulting
# detached signature must match B's fingerprint, not A's.
"${gpg_batch[@]}" --default-key "$fpr_b" \
  --detach-sign -o "$tmpdir/plain.sig" "$tmpdir/plain.txt"

gpg --list-packets "$tmpdir/plain.sig" >"$tmpdir/packets" 2>&1
validator_assert_contains "$tmpdir/packets" ':signature packet:'

# Pull issuer fingerprint from the signature packet.
issuer_fpr=$(awk '
  /issuer fpr/ {
    for (i = 1; i <= NF; i++) {
      if ($i ~ /^[0-9A-Fa-f]{40}$/) {
        print toupper($i)
        exit
      }
    }
  }
' "$tmpdir/packets")

if [[ -z "$issuer_fpr" ]]; then
  # Older list-packets output: fall back to the long keyid.
  long_id_b="${fpr_b: -16}"
  if grep -qi "keyid $long_id_b" "$tmpdir/packets"; then
    exit 0
  fi
  printf 'no issuer fingerprint or matching keyid found in packets:\n' >&2
  cat "$tmpdir/packets" >&2
  exit 1
fi

if [[ "$issuer_fpr" != "${fpr_b^^}" ]]; then
  printf 'signature issuer mismatch:\n  expected %s (key B)\n  actual   %s\n' \
    "${fpr_b^^}" "$issuer_fpr" >&2
  cat "$tmpdir/packets" >&2
  exit 1
fi
