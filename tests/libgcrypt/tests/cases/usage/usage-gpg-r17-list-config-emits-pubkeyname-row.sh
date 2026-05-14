#!/usr/bin/env bash
# @testcase: usage-gpg-r17-list-config-emits-pubkeyname-row
# @title: gpg --list-config --with-colons emits a pubkeyname row
# @description: Runs gpg --list-config --with-colons under an ephemeral GNUPGHOME and asserts the output contains at least one line matching the "cfg:pubkeyname:" prefix, exercising gpg's --list-config reflection of libgcrypt's registered public-key algorithm list (without requiring a specific algorithm name).
# @timeout: 60
# @tags: usage, gpg, list-config, pubkeyname
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg --list-config --with-colons >"$tmpdir/out" 2>"$tmpdir/err"

if ! LC_ALL=C grep -Eq '^cfg:pubkeyname:' "$tmpdir/out"; then
  echo 'no pubkeyname row in --list-config output' >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
