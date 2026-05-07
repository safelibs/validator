#!/usr/bin/env bash
# @testcase: usage-gpg-r14-list-config-compressname-includes-zip
# @title: gpg --list-config compressname reports ZIP among the supported compression algorithms
# @description: Runs gpg --with-colons --list-config compressname under an ephemeral GNUPGHOME and asserts the colon-format record contains both Uncompressed and ZIP among the supported compression algorithms (libgcrypt-backed compression registration).
# @timeout: 60
# @tags: usage, gpg, list-config, compress
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg --batch --with-colons --list-config compressname >"$tmpdir/cfg" 2>/dev/null

# cfg:compressname:Uncompressed;ZIP;ZLIB;BZIP2  (semicolon-separated list).
LC_ALL=C grep -E '^cfg:compressname:' "$tmpdir/cfg" >/dev/null
LC_ALL=C grep -E '^cfg:compressname:.*\bUncompressed\b' "$tmpdir/cfg" >/dev/null
LC_ALL=C grep -E '^cfg:compressname:.*\bZIP\b'         "$tmpdir/cfg" >/dev/null
