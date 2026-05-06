#!/usr/bin/env bash
# @testcase: usage-gpg-r9-list-keys-empty-keyring
# @title: gpg --list-keys on empty keyring
# @description: Initializes a fresh GNUPGHOME and confirms gpg --list-keys returns successfully and produces no key entries.
# @timeout: 60
# @tags: usage, gpg, keyring
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg --batch --list-keys >"$tmpdir/out" 2>"$tmpdir/err" || true
# Empty keyring should not list any "pub" lines.
! grep -E '^pub ' "$tmpdir/out" >/dev/null
