#!/usr/bin/env bash
# @testcase: usage-gpg-r17-import-non-key-file-fails
# @title: gpg --import on a non-key file exits non-zero
# @description: Attempts to import a plain text file (definitely not an OpenPGP keyring) via gpg --batch --import under an ephemeral GNUPGHOME and asserts the exit status is non-zero, exercising libgcrypt-backed gpg's keyring parser refusing to ingest random data.
# @timeout: 60
# @tags: usage, gpg, import, error
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

printf 'this is definitely not a pgp key\n' >"$tmpdir/not.key"

set +e
gpg --batch --import "$tmpdir/not.key" >"$tmpdir/out" 2>"$tmpdir/err"
rc=$?
set -e
if [[ $rc -eq 0 ]]; then
  printf 'expected non-zero exit on non-key import, got rc=%d\n' "$rc" >&2
  cat "$tmpdir/err" >&2
  exit 1
fi
