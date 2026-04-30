#!/usr/bin/env bash
# @testcase: usage-gpg-no-emit-version-armor
# @title: gpg --no-emit-version omits Version header in armor
# @description: Exports a public key in ASCII armor with --no-emit-version and asserts the resulting block contains the BEGIN/END armor markers but no "Version:" header line.
# @timeout: 180
# @tags: usage, gpg, armor
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-no-emit-version-armor"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
uid='Validator NoEmitVer <validator-noemitver@example.invalid>'

"${gpg_batch[@]}" --passphrase '' \
  --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1

"${gpg_batch[@]}" --no-emit-version --armor \
  --output "$tmpdir/pub.asc" --export "$uid"

validator_assert_contains "$tmpdir/pub.asc" '-----BEGIN PGP PUBLIC KEY BLOCK-----'
validator_assert_contains "$tmpdir/pub.asc" '-----END PGP PUBLIC KEY BLOCK-----'

# Inspect the armor header region (the lines between BEGIN and the first
# blank line). It must not contain a "Version:" line.
header_block=$(awk '
  /^-----BEGIN PGP PUBLIC KEY BLOCK-----/ {in_header = 1; next}
  in_header && /^$/                       {exit}
  in_header
' "$tmpdir/pub.asc")

if grep -Eq '^Version:' <<<"$header_block"; then
  printf '--no-emit-version armor unexpectedly emits Version: header\n' >&2
  printf '%s\n' "$header_block" >&2
  exit 1
fi

# Re-parse to make sure the armor is still well-formed (gpg can dearmor it).
gpg --list-packets "$tmpdir/pub.asc" >"$tmpdir/packets" 2>&1
validator_assert_contains "$tmpdir/packets" ':public key packet:'
