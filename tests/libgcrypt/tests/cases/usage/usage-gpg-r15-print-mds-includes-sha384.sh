#!/usr/bin/env bash
# @testcase: usage-gpg-r15-print-mds-includes-sha384
# @title: gpg --print-mds emits a SHA384 line alongside MD5 and SHA1 labels
# @description: Runs gpg --batch --print-mds on a fixed payload under an ephemeral GNUPGHOME and asserts the multi-digest listing contains the MD5, SHA1, and SHA384 algorithm labels — a libgcrypt digest-table coverage check distinct from the SHA224/SHA512 r13 variants.
# @timeout: 60
# @tags: usage, gpg, print-mds, digest, sha384, r15
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

printf 'r15 print-mds sha384 payload\n' >"$tmpdir/data.txt"

gpg --batch --print-mds "$tmpdir/data.txt" >"$tmpdir/out" 2>"$tmpdir/err"

validator_assert_contains "$tmpdir/out" 'MD5 ='
validator_assert_contains "$tmpdir/out" 'SHA1 ='
validator_assert_contains "$tmpdir/out" 'SHA384 ='
