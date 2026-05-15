#!/usr/bin/env bash
# @testcase: usage-gpg-r20-version-banner-compression-section
# @title: gpg --version banner advertises a Compression algorithm group
# @description: Runs gpg --version under an ephemeral GNUPGHOME and asserts the captured banner contains a "Compression:" or "Compress:" section label (libgcrypt-backed gpg always advertises its compiled-in compression algorithms in the version banner) - locking in the compression-section advertisement of the version banner.
# @timeout: 30
# @tags: usage, gpg, version, compression, r20
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg --version >"$tmpdir/v.txt" 2>"$tmpdir/err"

if ! LC_ALL=C grep -Eq '^(Compression|Compress):' "$tmpdir/v.txt"; then
    echo 'no Compression: section in --version banner' >&2
    cat "$tmpdir/v.txt" >&2
    exit 1
fi
