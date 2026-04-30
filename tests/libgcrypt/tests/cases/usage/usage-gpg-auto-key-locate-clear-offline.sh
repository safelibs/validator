#!/usr/bin/env bash
# @testcase: usage-gpg-auto-key-locate-clear-offline
# @title: gpg --auto-key-locate clear stays offline
# @description: Verifies that gpg --auto-key-locate clear disables every locate mechanism so verifying a signature from an unknown signer fails with NO_PUBKEY rather than performing any network lookup.
# @timeout: 180
# @tags: usage, gpg, offline, keys
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-auto-key-locate-clear-offline"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Signer keyring: produces a detached signature, then is discarded.
signer_home="$tmpdir/signer"
mkdir -p "$signer_home"
chmod 700 "$signer_home"

# Verifier keyring: never imports the signer's public key; must not reach
# the network when --auto-key-locate clear is in effect.
verifier_home="$tmpdir/verifier"
mkdir -p "$verifier_home"
chmod 700 "$verifier_home"

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
signer_uid='Validator AKLSigner <validator-aklsigner@example.invalid>'

GNUPGHOME="$signer_home" \
  "${gpg_batch[@]}" --passphrase '' \
    --quick-generate-key "$signer_uid" ed25519 sign 1d >/dev/null 2>&1

printf 'auto-key-locate offline payload\n' >"$tmpdir/plain.txt"
GNUPGHOME="$signer_home" \
  "${gpg_batch[@]}" --local-user "$signer_uid" \
    --detach-sign -o "$tmpdir/plain.sig" "$tmpdir/plain.txt"

# Verify against a fresh keyring with all locate mechanisms disabled.
status=0
GNUPGHOME="$verifier_home" \
  gpg --batch --auto-key-locate clear --keyserver-options no-honor-keyserver-url \
    --verify "$tmpdir/plain.sig" "$tmpdir/plain.txt" \
    >"$tmpdir/verify.out" 2>"$tmpdir/verify.err" || status=$?

if [[ "$status" -eq 0 ]]; then
  printf 'gpg --verify unexpectedly succeeded with --auto-key-locate clear\n' >&2
  cat "$tmpdir/verify.err" >&2
  exit 1
fi

# The verifier must report no public key, not a network/keyserver error.
if ! grep -Eq 'NO_PUBKEY|public key not found|Cant check signature|No public key' \
      "$tmpdir/verify.err"; then
  printf 'unexpected gpg verify diagnostics:\n' >&2
  cat "$tmpdir/verify.err" >&2
  exit 1
fi
