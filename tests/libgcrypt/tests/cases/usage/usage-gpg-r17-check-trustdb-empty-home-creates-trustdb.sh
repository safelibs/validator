#!/usr/bin/env bash
# @testcase: usage-gpg-r17-check-trustdb-empty-home-creates-trustdb
# @title: gpg --check-trustdb on a fresh GNUPGHOME exits zero and creates trustdb.gpg
# @description: Creates a brand-new GNUPGHOME with no keys, runs gpg --batch --check-trustdb, and asserts the exit status is zero and a trustdb.gpg file exists afterwards, exercising libgcrypt-backed gpg's trustdb walk on a key-less keyring (distinct from the existing test that requires a generated key first).
# @timeout: 60
# @tags: usage, gpg, trustdb, empty-home
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg --batch --check-trustdb >"$tmpdir/out" 2>"$tmpdir/err"

validator_require_file "$GNUPGHOME/trustdb.gpg"
