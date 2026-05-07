#!/usr/bin/env bash
# @testcase: usage-gpg-r12-version-banner-includes-libgcrypt
# @title: gpg --version banner advertises libgcrypt linkage
# @description: Runs gpg --version against an ephemeral GNUPGHOME and verifies the banner includes both "gpg (GnuPG)" and "libgcrypt" markers, confirming gpg dynamically links and reports the libgcrypt runtime.
# @timeout: 60
# @tags: usage, gpg, version, libgcrypt
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg --version >"$tmpdir/out" 2>&1

validator_assert_contains "$tmpdir/out" 'gpg (GnuPG)'
validator_assert_contains "$tmpdir/out" 'libgcrypt'
