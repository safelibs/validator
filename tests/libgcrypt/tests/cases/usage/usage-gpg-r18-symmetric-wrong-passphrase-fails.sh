#!/usr/bin/env bash
# @testcase: usage-gpg-r18-symmetric-wrong-passphrase-fails
# @title: gpg --decrypt with the wrong passphrase on a --symmetric ciphertext fails
# @description: Symmetrically encrypts a fixed plaintext with passphrase A, then attempts to decrypt with passphrase B via --pinentry-mode loopback and asserts the decrypt exit code is non-zero, exercising libgcrypt's S2K integrity-check / MDC failure path on a wrong-passphrase attempt.
# @timeout: 120
# @tags: usage, gpg, symmetric, wrong-passphrase, error, r18
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

printf 'wrong-passphrase r18 payload\n' >"$tmpdir/plain.txt"

gpg --batch --yes --pinentry-mode loopback \
    --passphrase 'correct-pp-A' \
    --symmetric --output "$tmpdir/cipher.gpg" "$tmpdir/plain.txt" \
    2>"$tmpdir/enc.err"

validator_require_file "$tmpdir/cipher.gpg"

set +e
gpg --batch --yes --pinentry-mode loopback \
    --passphrase 'wrong-pp-B' \
    --decrypt --output "$tmpdir/decrypted.txt" "$tmpdir/cipher.gpg" \
    >"$tmpdir/dec.out" 2>"$tmpdir/dec.err"
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  echo 'expected non-zero exit when decrypting with wrong passphrase' >&2
  cat "$tmpdir/dec.err" >&2
  exit 1
fi
