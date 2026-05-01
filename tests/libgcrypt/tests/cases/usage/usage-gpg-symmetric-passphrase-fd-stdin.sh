#!/usr/bin/env bash
# @testcase: usage-gpg-symmetric-passphrase-fd-stdin
# @title: gpg symmetric encryption with passphrase-fd 0
# @description: Encrypts symmetrically while supplying the passphrase on file descriptor 0 via --passphrase-fd 0 and confirms the decrypt roundtrip succeeds.
# @timeout: 180
# @tags: usage, gpg, crypto
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-symmetric-passphrase-fd-stdin"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

printf 'passphrase-fd payload\n' >"$tmpdir/plain.txt"
plain_sha=$(sha256sum "$tmpdir/plain.txt" | awk '{print $1}')

printf 'fd-passphrase' | gpg --batch --yes --pinentry-mode loopback \
  --passphrase-fd 0 --cipher-algo AES256 \
  --symmetric -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"
test -s "$tmpdir/plain.gpg"

printf 'fd-passphrase' | gpg --batch --yes --pinentry-mode loopback \
  --passphrase-fd 0 --decrypt -o "$tmpdir/out.txt" "$tmpdir/plain.gpg"

out_sha=$(sha256sum "$tmpdir/out.txt" | awk '{print $1}')
test "$plain_sha" = "$out_sha"
