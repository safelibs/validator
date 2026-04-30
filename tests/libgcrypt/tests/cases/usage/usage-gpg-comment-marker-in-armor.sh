#!/usr/bin/env bash
# @testcase: usage-gpg-comment-marker-in-armor
# @title: gpg --comment writes Comment header in armor
# @description: Exports a public key in ASCII armor with a custom --comment marker and asserts the marker appears as a Comment: header inside the armor while the armor remains parseable by gpg --list-packets.
# @timeout: 180
# @tags: usage, gpg, armor
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-comment-marker-in-armor"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
uid='Validator Comment <validator-comment@example.invalid>'
marker='validator-comment-marker-7c3f2'

"${gpg_batch[@]}" --passphrase '' \
  --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1

"${gpg_batch[@]}" --comment "$marker" --armor \
  --output "$tmpdir/pub.asc" --export "$uid"

validator_assert_contains "$tmpdir/pub.asc" '-----BEGIN PGP PUBLIC KEY BLOCK-----'
validator_assert_contains "$tmpdir/pub.asc" "Comment: $marker"

# The Comment: line must live inside the armor header block, before the first
# blank line that separates headers from the base64 body.
header_block=$(awk '
  /^-----BEGIN PGP PUBLIC KEY BLOCK-----/ {in_header = 1; next}
  in_header && /^$/                       {exit}
  in_header
' "$tmpdir/pub.asc")

if ! grep -Fq "Comment: $marker" <<<"$header_block"; then
  printf 'Comment marker not found in armor header region\n' >&2
  printf '%s\n' "$header_block" >&2
  exit 1
fi

# gpg must still be able to parse the armor with a custom comment header.
gpg --list-packets "$tmpdir/pub.asc" >"$tmpdir/packets" 2>&1
validator_assert_contains "$tmpdir/packets" ':public key packet:'
