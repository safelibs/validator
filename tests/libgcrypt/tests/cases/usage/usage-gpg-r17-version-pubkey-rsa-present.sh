#!/usr/bin/env bash
# @testcase: usage-gpg-r17-version-pubkey-rsa-present
# @title: gpg --version banner Pubkey algorithm list mentions RSA
# @description: Runs gpg --version under an ephemeral GNUPGHOME and asserts the banner contains the substring "RSA" in its compiled-in Pubkey algorithm list (gpg 2.4 emits "Pubkey: RSA, ELG, DSA, ECDH, ECDSA, EDDSA" on noble), exercising libgcrypt's compiled-in public-key algorithm reflection through gpg --version.
# @timeout: 60
# @tags: usage, gpg, version, pubkey, rsa
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg --version >"$tmpdir/v.out" 2>"$tmpdir/v.err"
LC_ALL=C grep -E '^Pubkey:' "$tmpdir/v.out" >"$tmpdir/pubkey.row" || {
  echo 'no Pubkey: row in gpg --version banner' >&2
  cat "$tmpdir/v.out" >&2
  exit 1
}
LC_ALL=C grep -q 'RSA' "$tmpdir/pubkey.row" || {
  echo 'RSA missing from Pubkey row' >&2
  cat "$tmpdir/pubkey.row" >&2
  exit 1
}
