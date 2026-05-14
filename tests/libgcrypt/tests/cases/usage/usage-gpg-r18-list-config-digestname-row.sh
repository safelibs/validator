#!/usr/bin/env bash
# @testcase: usage-gpg-r18-list-config-digestname-row
# @title: gpg --list-config --with-colons emits a digestname row mentioning SHA256
# @description: Runs gpg --list-config --with-colons under an ephemeral GNUPGHOME, extracts the cfg:digestname: row, and asserts the field contains the literal token "SHA256" (libgcrypt always exposes SHA-256 in the gpg 2.4 digest registry), exercising gpg's --list-config reflection of libgcrypt's digest algorithm list.
# @timeout: 60
# @tags: usage, gpg, list-config, digestname, sha256, r18
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg --list-config --with-colons >"$tmpdir/out" 2>"$tmpdir/err"
LC_ALL=C grep -E '^cfg:digestname:' "$tmpdir/out" >"$tmpdir/row" || {
  echo 'no cfg:digestname: row in --list-config output' >&2
  cat "$tmpdir/out" >&2
  exit 1
}
LC_ALL=C grep -q 'SHA256' "$tmpdir/row" || {
  echo 'SHA256 missing from cfg:digestname: row' >&2
  cat "$tmpdir/row" >&2
  exit 1
}
