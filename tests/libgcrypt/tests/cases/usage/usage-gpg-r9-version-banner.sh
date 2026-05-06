#!/usr/bin/env bash
# @testcase: usage-gpg-r9-version-banner
# @title: gpg --version reports banner
# @description: Runs gpg --version and confirms the banner reports the gpg program identity and exits zero.
# @timeout: 60
# @tags: usage, gpg, version
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gpg --version >"$tmpdir/out" 2>&1
validator_assert_contains "$tmpdir/out" 'gpg (GnuPG)'
grep -E '^[ ]*Home:|Compression|Hash|Cipher' "$tmpdir/out" >/dev/null
