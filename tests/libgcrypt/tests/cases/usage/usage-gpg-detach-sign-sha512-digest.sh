#!/usr/bin/env bash
# @testcase: usage-gpg-detach-sign-sha512-digest
# @title: gpg detach sign with SHA512 digest
# @description: Generates an ed25519 key, creates an armored detached signature with --digest-algo SHA512, and confirms gpg --verify reports a good signature.
# @timeout: 240
# @tags: usage, gpg, signature
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-detach-sign-sha512-digest"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
uid='Validator SHA512 <validator-sha512@example.invalid>'

"${gpg_batch[@]}" --passphrase '' \
  --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1

printf 'sha512 detached signature payload\n' >"$tmpdir/plain.txt"

"${gpg_batch[@]}" --passphrase '' --digest-algo SHA512 --armor \
  --detach-sign -o "$tmpdir/plain.asc" "$tmpdir/plain.txt"

head -n 1 "$tmpdir/plain.asc" >"$tmpdir/sig-head"
validator_assert_contains "$tmpdir/sig-head" '-----BEGIN PGP SIGNATURE-----'

gpg --verify "$tmpdir/plain.asc" "$tmpdir/plain.txt" >"$tmpdir/out" 2>&1
validator_assert_contains "$tmpdir/out" 'Good signature'

# The signature packet must record SHA512 as the digest algorithm.
gpg --list-packets "$tmpdir/plain.asc" >"$tmpdir/packets" 2>&1
validator_assert_contains "$tmpdir/packets" 'digest algo 10'
