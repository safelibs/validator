#!/usr/bin/env bash
# @testcase: usage-gpg-r21-list-config-curve-includes-cv25519
# @title: gpg --list-config --with-colons cfg:curve row includes cv25519
# @description: Runs gpg --list-config --with-colons under an ephemeral GNUPGHOME, extracts the cfg:curve: row, and asserts that splitting it on semicolons yields a token equal to exactly "cv25519" - locking in libgcrypt's cv25519 ECDH curve registration as a distinct semicolon token in gpg's compiled-in curve list (existing rounds checked ed25519, nistp256, secp256k1 but not cv25519 token-wise).
# @timeout: 60
# @tags: usage, gpg, list-config, curve, cv25519, r21
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg --list-config --with-colons >"$tmpdir/out" 2>"$tmpdir/err"
LC_ALL=C grep -E '^cfg:curve:' "$tmpdir/out" >"$tmpdir/row" || {
    echo 'no cfg:curve: row in --list-config output' >&2
    cat "$tmpdir/out" >&2
    exit 1
}

# Strip the cfg:curve: prefix and split on ';'.
LC_ALL=C sed 's/^cfg:curve://' "$tmpdir/row" | LC_ALL=C tr ';' '\n' | LC_ALL=C tr -d '\r' >"$tmpdir/tokens"

LC_ALL=C grep -Fxq 'cv25519' "$tmpdir/tokens" || {
    echo 'cv25519 not present as a discrete curve token' >&2
    cat "$tmpdir/tokens" >&2
    exit 1
}
