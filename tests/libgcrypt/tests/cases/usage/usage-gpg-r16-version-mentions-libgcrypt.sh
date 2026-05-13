#!/usr/bin/env bash
# @testcase: usage-gpg-r16-version-mentions-libgcrypt
# @title: gpg --version banner mentions Libgcrypt
# @description: Runs gpg --version under an ephemeral GNUPGHOME and asserts the banner contains the substring "Libgcrypt", confirming the gpg binary is linked against libgcrypt and reports its name in the version block.
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

gpg --version >"$tmpdir/v.out" 2>"$tmpdir/v.err"
validator_assert_contains "$tmpdir/v.out" "Libgcrypt"
