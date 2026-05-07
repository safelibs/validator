#!/usr/bin/env bash
# @testcase: usage-gpg-r12-export-armor-public-key-banner
# @title: gpg --armor --export emits a PUBLIC KEY BLOCK ASCII-armor banner
# @description: Generates an Ed25519 key in an ephemeral GNUPGHOME, exports it with --armor --export, and verifies the output starts and ends with the canonical "BEGIN PGP PUBLIC KEY BLOCK" / "END PGP PUBLIC KEY BLOCK" markers.
# @timeout: 240
# @tags: usage, gpg, export, armor
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

uid='Validator R12 Export <r12-export@example.invalid>'
gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1

gpg --batch --armor --export >"$tmpdir/pub.asc" 2>/dev/null
[[ -s "$tmpdir/pub.asc" ]] || { echo 'empty exported public key' >&2; exit 1; }

head -n1 "$tmpdir/pub.asc" | grep -qx -- '-----BEGIN PGP PUBLIC KEY BLOCK-----'
tail -n1 "$tmpdir/pub.asc" | grep -qx -- '-----END PGP PUBLIC KEY BLOCK-----'
