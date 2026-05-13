#!/usr/bin/env bash
# @testcase: usage-gpg-r16-list-config-ciphername-includes-aes256
# @title: gpg --list-config ciphername line lists AES256
# @description: Runs gpg --list-config under an ephemeral GNUPGHOME and asserts the "ciphername:" row mentions AES256 (libgcrypt provides AES with a 256-bit key as a registered cipher), exercising gpg's --list-config reflection of libgcrypt's compiled-in ciphers.
# @timeout: 60
# @tags: usage, gpg, list-config, aes256
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg --list-config --with-colons >"$tmpdir/out" 2>"$tmpdir/err"

LC_ALL=C grep -E '^cfg:ciphername:' "$tmpdir/out" >"$tmpdir/cipher.row" || {
  echo 'no ciphername row in --list-config output' >&2
  cat "$tmpdir/out" >&2
  exit 1
}
LC_ALL=C grep -q 'AES256' "$tmpdir/cipher.row" || {
  echo 'AES256 missing from ciphername row' >&2
  cat "$tmpdir/cipher.row" >&2
  exit 1
}
