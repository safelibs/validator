#!/usr/bin/env bash
# @testcase: usage-gpg-r15-symmetric-twofish-cipher-10-roundtrip
# @title: gpg --symmetric --cipher-algo TWOFISH round-trips and records cipher 10 in the symkey-enc packet
# @description: Symmetrically encrypts a fixed payload with --cipher-algo TWOFISH and a passphrase under an ephemeral GNUPGHOME, asserts the resulting symkey-enc packet declares cipher 10 (Twofish per RFC 4880), then decrypts and asserts the recovered plaintext matches the input via cmp.
# @timeout: 60
# @tags: usage, gpg, symmetric, twofish, r15
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

printf 'r15 symmetric twofish payload\n' >"$tmpdir/plain.txt"
pp='r15-twofish-pp'

gpg --batch --yes --pinentry-mode loopback --passphrase "$pp" \
  --cipher-algo TWOFISH \
  --symmetric -o "$tmpdir/cipher.gpg" "$tmpdir/plain.txt"

gpg --batch --yes --pinentry-mode loopback --passphrase "$pp" \
  --list-packets "$tmpdir/cipher.gpg" >"$tmpdir/packets" 2>&1

# RFC 4880: cipher 10 = Twofish-256.
LC_ALL=C grep -E 'symkey enc packet:.*cipher 10\b' "$tmpdir/packets" >/dev/null || {
  echo 'expected cipher 10 (Twofish) in symkey-enc packet' >&2
  cat "$tmpdir/packets" >&2
  exit 1
}

gpg --batch --yes --pinentry-mode loopback --passphrase "$pp" \
  --decrypt -o "$tmpdir/round.txt" "$tmpdir/cipher.gpg" >/dev/null 2>&1

cmp "$tmpdir/plain.txt" "$tmpdir/round.txt"
