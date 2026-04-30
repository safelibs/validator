#!/usr/bin/env bash
# @testcase: usage-gpg-no-armor-explicit-binary
# @title: gpg --no-armor explicit binary export
# @description: Forces a binary OpenPGP public-key export with an explicit --no-armor and confirms the output starts with the OpenPGP packet magic byte rather than ASCII armor headers.
# @timeout: 180
# @tags: usage, gpg, armor, binary
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-no-armor-explicit-binary"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg_batch=(gpg --batch --yes --pinentry-mode loopback)
uid='Validator NoArmor <validator-noarmor@example.invalid>'

"${gpg_batch[@]}" --passphrase '' \
  --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1

# Pass --armor first to confirm --no-armor wins when given last; gpg honours
# the last form on the command line.
"${gpg_batch[@]}" --armor --no-armor \
  --output "$tmpdir/pub.bin" --export "$uid"

test -s "$tmpdir/pub.bin"

# An ASCII-armored block would start with '-----BEGIN PGP'; binary OpenPGP
# packets begin with the high bit set (0x80 or above). 0x98 is the typical
# old-format public-key packet tag emitted by gpg.
first_byte=$(od -An -N1 -tx1 "$tmpdir/pub.bin" | tr -d ' \n')
if [[ "$first_byte" == "2d" ]]; then
  printf '--no-armor produced ASCII armor output\n' >&2
  head -c 64 "$tmpdir/pub.bin" >&2
  exit 1
fi

# High bit must be set on the first packet header byte.
first_dec=$((16#${first_byte}))
if (( first_dec < 128 )); then
  printf 'unexpected first byte 0x%s in --no-armor output\n' "$first_byte" >&2
  exit 1
fi

# Confirm gpg parses the binary blob back as an OpenPGP public key packet.
gpg --list-packets "$tmpdir/pub.bin" >"$tmpdir/packets" 2>&1
validator_assert_contains "$tmpdir/packets" ':public key packet:'
