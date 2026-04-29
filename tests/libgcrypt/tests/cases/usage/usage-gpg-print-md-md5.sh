#!/usr/bin/env bash
# @testcase: usage-gpg-print-md-md5
# @title: gpg MD5 digest
# @description: Prints an MD5 digest with gpg and verifies digest text is emitted.
# @timeout: 180
# @tags: usage, gpg, digest
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-print-md-md5"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"
gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
passphrase=validator-passphrase
uid='Validator Further <validator-further@example.invalid>'

make_signing_key() {
  "${gpg_batch[@]}" --passphrase '' --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1
}

printf 'digest payload\n' >"$tmpdir/plain.txt"
gpg --print-md MD5 "$tmpdir/plain.txt" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'plain.txt:'
grep -Eq '[0-9A-F]{2} [0-9A-F]{2}' "$tmpdir/out"
