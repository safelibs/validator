#!/usr/bin/env bash
# @testcase: usage-gpg-r18-list-config-curve-mentions-secp256k1
# @title: gpg --list-config --with-colons emits a cfg:curve: row mentioning secp256k1
# @description: Runs gpg --list-config --with-colons under an ephemeral GNUPGHOME, extracts the cfg:curve: row, and asserts the field contains the literal token "secp256k1" (libgcrypt 1.10 on noble ships secp256k1 as part of the gpg curve registry), exercising gpg's --list-config reflection of libgcrypt's curve list.
# @timeout: 60
# @tags: usage, gpg, list-config, curve, secp256k1, r18
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg --list-config --with-colons >"$tmpdir/out" 2>"$tmpdir/err"
LC_ALL=C grep -E '^cfg:curve:' "$tmpdir/out" >"$tmpdir/row" || {
  echo 'no cfg:curve: row in --list-config output' >&2
  cat "$tmpdir/out" >&2
  exit 1
}
LC_ALL=C grep -q 'secp256k1' "$tmpdir/row" || {
  echo 'secp256k1 missing from cfg:curve: row' >&2
  cat "$tmpdir/row" >&2
  exit 1
}
