#!/usr/bin/env bash
# @testcase: usage-gpg-r14-list-secret-keys-empty-home
# @title: gpg -K on a fresh GNUPGHOME emits no sec records
# @description: Creates a brand-new ephemeral GNUPGHOME, runs gpg --batch --with-colons -K (the short form of --list-secret-keys), and asserts the colon output contains zero sec: records (no secret keys present).
# @timeout: 60
# @tags: usage, gpg, list-secret-keys
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg --batch --with-colons -K >"$tmpdir/colons" 2>"$tmpdir/err" || true

sec_count=$(LC_ALL=C awk -F: '$1=="sec"{n++} END{print n+0}' "$tmpdir/colons")
[[ "$sec_count" -eq 0 ]] || {
  printf 'expected 0 sec records, got %s\n' "$sec_count" >&2
  cat "$tmpdir/colons" >&2
  exit 1
}
