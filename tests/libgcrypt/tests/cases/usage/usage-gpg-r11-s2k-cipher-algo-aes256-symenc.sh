#!/usr/bin/env bash
# @testcase: usage-gpg-r11-s2k-cipher-algo-aes256-symenc
# @title: gpg --s2k-cipher-algo AES256 selects cipher 9 in the symkey-enc packet
# @description: Symmetrically encrypts a payload with --s2k-cipher-algo AES256 and verifies --list-packets reports cipher 9 in the symkey-enc packet (OpenPGP RFC 4880 sym alg 9 is AES-256).
# @timeout: 120
# @tags: usage, gpg, symmetric, s2k-cipher-algo
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

printf 's2k cipher payload\n' >"$tmpdir/plain.txt"
gpg --batch --yes --pinentry-mode loopback --passphrase 'pp' \
  --s2k-cipher-algo AES256 \
  --symmetric -o "$tmpdir/cipher.gpg" "$tmpdir/plain.txt"

gpg --batch --yes --pinentry-mode loopback --passphrase 'pp' \
  --list-packets "$tmpdir/cipher.gpg" >"$tmpdir/packets" 2>&1

grep -E 'symkey enc packet:.*cipher 9\b' "$tmpdir/packets" >/dev/null || {
  echo 'expected symkey-enc packet with cipher 9 (AES256)' >&2
  cat "$tmpdir/packets" >&2
  exit 1
}
