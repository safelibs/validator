#!/usr/bin/env bash
# @testcase: usage-gpg-weak-digest-sha1-rejects-verify
# @title: gpg --weak-digest SHA1 rejects SHA1 signatures on verify
# @description: Demonstrates the --weak-digest contract: a SHA256 detached signature still verifies under --weak-digest SHA1, while a SHA1-digest detached signature is rejected with an "Invalid digest algorithm" error.
# @timeout: 240
# @tags: usage, gpg, digest, weak-digest
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-weak-digest-sha1-rejects-verify"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"
export GNUPGHOME

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
uid='Weak Digest Signer <weakdigest@example.invalid>'

"${gpg_batch[@]}" --passphrase '' --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1

printf 'weak digest payload\n' >"$tmpdir/plain.txt"

# Strong baseline: SHA256 sig must verify even when SHA1 is marked weak.
"${gpg_batch[@]}" --digest-algo SHA256 --detach-sign \
  -o "$tmpdir/sha256.sig" "$tmpdir/plain.txt"
gpg --weak-digest SHA1 --verify "$tmpdir/sha256.sig" "$tmpdir/plain.txt" \
  >"$tmpdir/verify_sha256.out" 2>&1
validator_assert_contains "$tmpdir/verify_sha256.out" 'Good signature'

# Weak case: SHA1 sig must be rejected when SHA1 is marked weak.
"${gpg_batch[@]}" --digest-algo SHA1 --detach-sign \
  -o "$tmpdir/sha1.sig" "$tmpdir/plain.txt"

set +e
gpg --weak-digest SHA1 --verify "$tmpdir/sha1.sig" "$tmpdir/plain.txt" \
  >"$tmpdir/verify_sha1.out" 2>&1
rc=$?
set -e

if [[ $rc -eq 0 ]]; then
  echo "expected --weak-digest SHA1 to reject a SHA1 signature, but verify succeeded" >&2
  cat "$tmpdir/verify_sha1.out" >&2
  exit 1
fi

validator_assert_contains "$tmpdir/verify_sha1.out" 'Invalid digest algorithm'
