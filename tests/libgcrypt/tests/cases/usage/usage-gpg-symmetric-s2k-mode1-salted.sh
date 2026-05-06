#!/usr/bin/env bash
# @testcase: usage-gpg-symmetric-s2k-mode1-salted
# @title: gpg symmetric s2k mode 1 salted only
# @description: Encrypts symmetrically with --s2k-mode 1 (salted, no iteration) and confirms --list-packets shows mode 1 and a successful roundtrip decrypt.
# @timeout: 180
# @tags: usage, gpg, crypto
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-symmetric-s2k-mode1-salted"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)

printf 's2k mode 1 payload\n' >"$tmpdir/plain.txt"
plain_sha=$(sha256sum "$tmpdir/plain.txt" | awk '{print $1}')

"${gpg_batch[@]}" --passphrase 'test' \
  --s2k-mode 1 --cipher-algo AES256 --s2k-digest-algo SHA256 \
  --symmetric -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"

# list-packets exits non-zero on symmetric blobs (no passphrase to decrypt the
# inner payload) but still emits the symkey enc packet line we need. gpg
# encodes s2k mode 1 (salted-only) as "s2k 1" in the symkey packet line.
gpg --list-packets "$tmpdir/plain.gpg" >"$tmpdir/packets" 2>&1 || true
grep -Eqi 's2k 1|mode 1|salted' "$tmpdir/packets"

"${gpg_batch[@]}" --passphrase 'test' --decrypt \
  -o "$tmpdir/out.txt" "$tmpdir/plain.gpg"
out_sha=$(sha256sum "$tmpdir/out.txt" | awk '{print $1}')
test "$plain_sha" = "$out_sha"
