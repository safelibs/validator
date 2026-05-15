#!/usr/bin/env bash
# @testcase: usage-gpg-r19-list-config-compressname-zlib
# @title: gpg --list-config --with-colons compressname row mentions ZLIB
# @description: Runs gpg --list-config --with-colons under an ephemeral GNUPGHOME, extracts the cfg:compressname: row, and asserts the field contains the literal token "ZLIB" (libgcrypt always exposes ZLIB in the gpg 2.4 compression algorithm registry), exercising gpg's --list-config reflection of the compiled-in compression list.
# @timeout: 60
# @tags: usage, gpg, list-config, compressname, zlib, r19
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg --list-config --with-colons >"$tmpdir/out" 2>"$tmpdir/err"
LC_ALL=C grep -E '^cfg:compressname:' "$tmpdir/out" >"$tmpdir/row" || {
  echo 'no cfg:compressname: row in --list-config output' >&2
  cat "$tmpdir/out" >&2
  exit 1
}
LC_ALL=C grep -q 'ZLIB' "$tmpdir/row" || {
  echo 'ZLIB missing from cfg:compressname: row' >&2
  cat "$tmpdir/row" >&2
  exit 1
}
