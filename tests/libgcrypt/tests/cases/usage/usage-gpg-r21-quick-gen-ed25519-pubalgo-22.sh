#!/usr/bin/env bash
# @testcase: usage-gpg-r21-quick-gen-ed25519-pubalgo-22
# @title: gpg --quick-generate-key ed25519 produces a pub record with algorithm 22 (EdDSA)
# @description: Generates an ed25519 signing key in a fresh ephemeral GNUPGHOME using gpg --quick-generate-key, parses the resulting --with-colons --list-keys output for the pub record, and asserts field 4 (public-key algorithm id) is exactly 22 and field 17 (curve name) is exactly "ed25519" - locking in libgcrypt's ed25519 keygen registering with gpg's pubkey algorithm 22 (EdDSA) and reporting the curve via colons output (previous rounds covered RSA-3072 fingerprint uppercasing and nistp384 quick-gen but no algorithm-id assertion).
# @timeout: 240
# @tags: usage, gpg, quick-generate, ed25519, eddsa, r21
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

uid='Validator R21 Ed25519 <r21-ed25519@example.invalid>'
gpg --batch --yes --pinentry-mode loopback --passphrase '' \
    --quick-generate-key "$uid" ed25519 sign 1d >/dev/null 2>&1

gpg --batch --with-colons --list-keys >"$tmpdir/colons" 2>&1

algo=$(LC_ALL=C awk -F: '$1=="pub"{print $4; exit}' "$tmpdir/colons")
curve=$(LC_ALL=C awk -F: '$1=="pub"{print $17; exit}' "$tmpdir/colons")

[[ "$algo" == "22" ]] || { printf 'expected pubkey algo 22 (EdDSA), got %s\n' "$algo" >&2; cat "$tmpdir/colons" >&2; exit 1; }
[[ "$curve" == "ed25519" ]] || { printf 'expected curve ed25519, got %s\n' "$curve" >&2; cat "$tmpdir/colons" >&2; exit 1; }
