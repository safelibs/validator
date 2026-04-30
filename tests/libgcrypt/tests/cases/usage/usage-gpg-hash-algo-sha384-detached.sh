#!/usr/bin/env bash
# @testcase: usage-gpg-hash-algo-sha384-detached
# @title: gpg --digest-algo SHA384 detached signature roundtrip
# @description: Generates an ed25519 signing key, produces a detached signature with --digest-algo SHA384, verifies it, and asserts the signature packet metadata reports SHA384 (digest 9).
# @timeout: 240
# @tags: usage, gpg, signature, sha384
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-hash-algo-sha384-detached"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"
export GNUPGHOME

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
uid='SHA384 Signer <sha384@example.invalid>'

"${gpg_batch[@]}" --passphrase '' --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1

printf 'sha384 detached payload\n' >"$tmpdir/plain.txt"
"${gpg_batch[@]}" --digest-algo SHA384 --detach-sign -o "$tmpdir/plain.sig" "$tmpdir/plain.txt"

gpg --verify "$tmpdir/plain.sig" "$tmpdir/plain.txt" >"$tmpdir/verify.out" 2>&1
validator_assert_contains "$tmpdir/verify.out" 'Good signature'

# Inspect the signature packet to confirm SHA384 was used (digest_algo 9).
gpg --list-packets "$tmpdir/plain.sig" >"$tmpdir/packets.txt"
validator_assert_contains "$tmpdir/packets.txt" 'digest algo 9'
