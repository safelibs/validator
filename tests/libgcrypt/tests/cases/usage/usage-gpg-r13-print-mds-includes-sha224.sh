#!/usr/bin/env bash
# @testcase: usage-gpg-r13-print-mds-includes-sha224
# @title: gpg --print-mds emits SHA224 alongside SHA256 and SHA512 labels
# @description: Runs gpg --batch --print-mds on a fixed payload under an ephemeral GNUPGHOME, redirects stdout to a file, and asserts the listing includes the SHA224, SHA256, and SHA512 algorithm labels (libgcrypt digest table coverage).
# @timeout: 60
# @tags: usage, gpg, print-mds, digest
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

printf 'r13 print-mds payload\n' >"$tmpdir/data.txt"

gpg --batch --print-mds "$tmpdir/data.txt" >"$tmpdir/out" 2>"$tmpdir/err"

validator_assert_contains "$tmpdir/out" 'SHA224 ='
validator_assert_contains "$tmpdir/out" 'SHA256 ='
validator_assert_contains "$tmpdir/out" 'SHA512 ='
