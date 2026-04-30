#!/usr/bin/env bash
# @testcase: usage-gpg-textmode-encrypt-decrypt
# @title: gpg --textmode symmetric roundtrip
# @description: Symmetrically encrypts a multiline text payload with --textmode and decrypts it with --textmode, verifying the plaintext is preserved byte-for-byte.
# @timeout: 180
# @tags: usage, gpg, crypto
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-textmode-encrypt-decrypt"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"
gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
passphrase=validator-passphrase

{
  printf 'first text line\n'
  printf 'second text line\n'
  printf 'third text line\n'
} >"$tmpdir/plain.txt"

"${gpg_batch[@]}" --passphrase "$passphrase" --textmode --symmetric -o "$tmpdir/plain.gpg" "$tmpdir/plain.txt"
[[ -s "$tmpdir/plain.gpg" ]] || { printf 'expected non-empty ciphertext\n' >&2; exit 1; }

"${gpg_batch[@]}" --passphrase "$passphrase" --textmode --decrypt -o "$tmpdir/out.txt" "$tmpdir/plain.gpg"
diff "$tmpdir/plain.txt" "$tmpdir/out.txt" >"$tmpdir/diff" || {
  printf 'textmode roundtrip differs\n' >&2
  cat "$tmpdir/diff" >&2
  exit 1
}
validator_assert_contains "$tmpdir/out.txt" 'first text line'
validator_assert_contains "$tmpdir/out.txt" 'third text line'
