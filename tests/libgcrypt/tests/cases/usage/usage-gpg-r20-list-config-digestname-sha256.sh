#!/usr/bin/env bash
# @testcase: usage-gpg-r20-list-config-digestname-sha256
# @title: gpg --list-config --with-colons digestname row mentions SHA256
# @description: Runs gpg --list-config --with-colons under an ephemeral GNUPGHOME, extracts the cfg:digestname: row, and asserts it contains the literal token "SHA256" - locking in libgcrypt's SHA256 entry in gpg's compiled-in digest algorithm registry.
# @timeout: 60
# @tags: usage, gpg, list-config, digestname, sha256, r20
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg --list-config --with-colons >"$tmpdir/out" 2>"$tmpdir/err"
LC_ALL=C grep -E '^cfg:digestname:' "$tmpdir/out" >"$tmpdir/row" || {
    echo 'no cfg:digestname: row in --list-config output' >&2
    cat "$tmpdir/out" >&2
    exit 1
}
LC_ALL=C grep -q 'SHA256' "$tmpdir/row" || {
    echo 'SHA256 missing from cfg:digestname: row' >&2
    cat "$tmpdir/row" >&2
    exit 1
}
