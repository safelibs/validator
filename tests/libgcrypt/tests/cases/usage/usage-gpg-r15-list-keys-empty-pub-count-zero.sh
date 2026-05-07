#!/usr/bin/env bash
# @testcase: usage-gpg-r15-list-keys-empty-pub-count-zero
# @title: gpg --list-keys on a fresh GNUPGHOME emits zero pub: records
# @description: Creates a brand-new ephemeral GNUPGHOME, runs gpg --batch --with-colons --list-keys, counts pub: records via awk, and asserts the count is exactly zero — confirming the public keyring is empty when GNUPGHOME is freshly minted.
# @timeout: 60
# @tags: usage, gpg, list-keys, empty, r15
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg --batch --with-colons --list-keys >"$tmpdir/colons" 2>"$tmpdir/err" || true

pub_count=$(LC_ALL=C awk -F: '$1=="pub"{n++} END{print n+0}' "$tmpdir/colons")
[[ "$pub_count" -eq 0 ]] || {
  printf 'expected 0 pub records on empty home, got %s\n' "$pub_count" >&2
  cat "$tmpdir/colons" >&2
  exit 1
}
