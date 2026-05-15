#!/usr/bin/env bash
# @testcase: usage-gpg-r19-version-banner-cipher-3des-present
# @title: gpg --version banner Cipher row mentions 3DES
# @description: Runs gpg --version under an ephemeral GNUPGHOME and asserts the banner's "Cipher:" row contains the substring "3DES" (libgcrypt always compiles in the legacy 3DES cipher on the noble baseline), exercising libgcrypt's compiled-in cipher algorithm reflection through gpg --version.
# @timeout: 60
# @tags: usage, gpg, version, cipher, 3des, r19
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg --version >"$tmpdir/v.out" 2>"$tmpdir/v.err"
LC_ALL=C grep -E '^Cipher:' "$tmpdir/v.out" >"$tmpdir/row" || {
  echo 'no Cipher: row in --version banner' >&2
  cat "$tmpdir/v.out" >&2
  exit 1
}
LC_ALL=C grep -q '3DES' "$tmpdir/row" || {
  echo '3DES missing from Cipher row' >&2
  cat "$tmpdir/row" >&2
  exit 1
}
