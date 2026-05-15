#!/usr/bin/env bash
# @testcase: usage-gpg-r20-list-config-pubkeyname-mentions-dsa
# @title: gpg --list-config --with-colons pubkeyname row mentions DSA
# @description: Runs gpg --list-config --with-colons under an ephemeral GNUPGHOME, extracts the cfg:pubkeyname: row, and asserts it contains the literal token "DSA" - locking in libgcrypt's DSA entry in gpg's compiled-in public-key algorithm registry (distinct from prior RSA and ELG coverage).
# @timeout: 60
# @tags: usage, gpg, list-config, pubkeyname, dsa, r20
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg --list-config --with-colons >"$tmpdir/out" 2>"$tmpdir/err"
LC_ALL=C grep -E '^cfg:pubkeyname:' "$tmpdir/out" >"$tmpdir/row" || {
    echo 'no cfg:pubkeyname: row in --list-config output' >&2
    cat "$tmpdir/out" >&2
    exit 1
}
LC_ALL=C grep -q 'DSA' "$tmpdir/row" || {
    echo 'DSA missing from cfg:pubkeyname: row' >&2
    cat "$tmpdir/row" >&2
    exit 1
}
