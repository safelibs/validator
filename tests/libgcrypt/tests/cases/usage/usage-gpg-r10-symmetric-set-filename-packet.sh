#!/usr/bin/env bash
# @testcase: usage-gpg-r10-symmetric-set-filename-packet
# @title: gpg --symmetric records --set-filename in literal data packet
# @description: Symmetrically encrypts a payload using --set-filename original.bin and verifies gpg --list-packets reports that filename in the literal data packet header.
# @timeout: 120
# @tags: usage, gpg, symmetric, packets
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

printf 'set-filename payload\n' >"$tmpdir/plain.txt"
gpg --batch --yes --pinentry-mode loopback --passphrase 'pp' \
  --set-filename 'original.bin' \
  --symmetric -o "$tmpdir/cipher.gpg" "$tmpdir/plain.txt"
[[ -s "$tmpdir/cipher.gpg" ]]

gpg --batch --yes --pinentry-mode loopback --passphrase 'pp' \
  --list-packets "$tmpdir/cipher.gpg" >"$tmpdir/packets" 2>&1

validator_assert_contains "$tmpdir/packets" 'original.bin'
