#!/usr/bin/env bash
# @testcase: usage-gpg-gen-revoke-detached-reason-zero
# @title: gpg --gen-revoke produces armored revocation cert with reason 0
# @description: Drives gpg --gen-revoke with --command-fd to produce a detached armored revocation certificate using reason code 0 (no reason given), then asserts the resulting block is a class 0x20 signature packet whose hashed subpacket 29 (reason for revocation) carries 0x00.
# @timeout: 240
# @tags: usage, gpg, keys, revocation
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-gen-revoke-detached-reason-zero"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
uid='Validator GenRevokeR0 <validator-gen-revoke-r0@example.invalid>'

"${gpg_batch[@]}" --passphrase '' \
  --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1

# --gen-revoke is interactive; drive it via --command-fd, --no-tty, and
# --pinentry-mode loopback so it works headless. The four answers are:
#   y    -- yes, generate revocation cert
#   0    -- reason code (No reason specified)
#   ""   -- empty descriptive comment (terminator)
#   y    -- confirm "Is this okay?"
printf 'y\n0\n\ny\n' | gpg \
  --no-tty --yes --pinentry-mode loopback \
  --command-fd 0 --status-fd 2 \
  --passphrase '' --armor \
  --gen-revoke "$uid" \
  >"$tmpdir/revoke.asc" 2>"$tmpdir/revoke.status"

test -s "$tmpdir/revoke.asc"
grep -q '^-----BEGIN PGP PUBLIC KEY BLOCK-----' "$tmpdir/revoke.asc"
grep -q '^-----END PGP PUBLIC KEY BLOCK-----'   "$tmpdir/revoke.asc"

# Inspect the underlying signature packet.
gpg --list-packets "$tmpdir/revoke.asc" >"$tmpdir/packets" 2>&1
validator_assert_contains "$tmpdir/packets" ':signature packet:'
validator_assert_contains "$tmpdir/packets" 'sigclass 0x20'
# RFC 4880 section 5.2.3.23: subpacket type 29 is "Reason for Revocation",
# first byte = revocation code; 0x00 means "No reason specified".
validator_assert_contains "$tmpdir/packets" 'hashed subpkt 29'
validator_assert_contains "$tmpdir/packets" 'revocation reason 0x00'
