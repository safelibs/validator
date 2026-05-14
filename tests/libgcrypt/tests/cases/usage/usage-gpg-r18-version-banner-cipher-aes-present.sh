#!/usr/bin/env bash
# @testcase: usage-gpg-r18-version-banner-cipher-aes-present
# @title: gpg --version banner Cipher algorithm list mentions AES256
# @description: Runs gpg --version under an ephemeral GNUPGHOME and asserts the banner contains the substring "AES256" in its compiled-in Cipher algorithm list (gpg 2.4 on noble exposes AES, AES192, AES256, and others via libgcrypt), exercising libgcrypt's cipher algorithm reflection through gpg --version.
# @timeout: 60
# @tags: usage, gpg, version, cipher, aes256, r18
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg --version >"$tmpdir/v.out" 2>"$tmpdir/v.err"
LC_ALL=C grep -E '^Cipher:' "$tmpdir/v.out" >"$tmpdir/cipher.row" || {
  echo 'no Cipher: row in gpg --version banner' >&2
  cat "$tmpdir/v.out" >&2
  exit 1
}
LC_ALL=C grep -q 'AES256' "$tmpdir/cipher.row" || {
  echo 'AES256 missing from Cipher row' >&2
  cat "$tmpdir/cipher.row" >&2
  exit 1
}
