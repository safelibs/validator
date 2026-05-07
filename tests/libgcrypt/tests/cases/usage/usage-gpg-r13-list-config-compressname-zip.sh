#!/usr/bin/env bash
# @testcase: usage-gpg-r13-list-config-compressname-zip
# @title: gpg --list-config compressname includes ZIP, ZLIB, and BZIP2 algorithms
# @description: Captures cfg:compressname: via --with-colons --list-config compressname and asserts the configured compression algorithm list contains ZIP, ZLIB, and BZIP2, confirming libgcrypt's compressor wiring is intact.
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

gpg --with-colons --list-config compressname >"$tmpdir/out"

line=$(grep -E '^cfg:compressname:' "$tmpdir/out" | head -n1)
[[ -n "$line" ]]

for needle in ZIP ZLIB BZIP2; do
  case "$line" in
    *"$needle"*) ;;
    *) echo "$needle missing in: $line" >&2; exit 1 ;;
  esac
done
