#!/usr/bin/env bash
# @testcase: usage-gpg-r15-list-config-pubkeyname-includes-elg
# @title: gpg --list-config pubkeyname reports ELG among the supported public-key algorithms
# @description: Runs gpg --batch --with-colons --list-config pubkeyname under an ephemeral GNUPGHOME and asserts the colon record begins with the expected cfg:pubkeyname: prefix and contains both RSA and ELG (ElGamal) algorithm tokens — exercising libgcrypt's public-key registration table.
# @timeout: 60
# @tags: usage, gpg, list-config, pubkey, r15
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg --batch --with-colons --list-config pubkeyname >"$tmpdir/cfg" 2>/dev/null

LC_ALL=C grep -E '^cfg:pubkeyname:' "$tmpdir/cfg" >/dev/null
LC_ALL=C grep -E '^cfg:pubkeyname:.*\bRSA\b' "$tmpdir/cfg" >/dev/null
LC_ALL=C grep -E '^cfg:pubkeyname:.*\bELG\b' "$tmpdir/cfg" >/dev/null
