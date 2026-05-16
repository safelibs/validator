#!/usr/bin/env bash
# @testcase: usage-gpg-r21-enarmor-banner-comment-line
# @title: gpg --enarmor emits the PGP ARMORED FILE banner and the dearmor-comment line
# @description: Pipes a fixed 8-byte payload through gpg --enarmor and asserts the captured output contains the exact "-----BEGIN PGP ARMORED FILE-----" banner, the literal Comment line advising "gpg --dearmor" for unpacking, and the closing "-----END PGP ARMORED FILE-----" trailer - locking in libgcrypt's enarmor banner shape that wraps a non-OpenPGP-message radix-64 block.
# @timeout: 60
# @tags: usage, gpg, enarmor, banner, r21
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

printf 'r21body!' | gpg --enarmor >"$tmpdir/out" 2>"$tmpdir/err"
validator_assert_contains "$tmpdir/out" '-----BEGIN PGP ARMORED FILE-----'
validator_assert_contains "$tmpdir/out" 'Comment: Use "gpg --dearmor" for unpacking'
validator_assert_contains "$tmpdir/out" '-----END PGP ARMORED FILE-----'
