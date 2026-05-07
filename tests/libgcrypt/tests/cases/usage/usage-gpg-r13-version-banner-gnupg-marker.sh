#!/usr/bin/env bash
# @testcase: usage-gpg-r13-version-banner-gnupg-marker
# @title: gpg --version banner starts with "gpg (GnuPG)"
# @description: Captures gpg --version output under an ephemeral GNUPGHOME and asserts the very first line begins with the canonical "gpg (GnuPG)" identifier so downstream parsers can recognise the implementation.
# @timeout: 60
# @tags: usage, gpg, version
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg --version >"$tmpdir/out" 2>"$tmpdir/err"

first=$(sed -n '1p' "$tmpdir/out")
case "$first" in
  'gpg (GnuPG) '*) ;;
  *)
    echo "unexpected first line: $first" >&2
    cat "$tmpdir/out" >&2
    exit 1
    ;;
esac

# Also assert a numeric version follows.
echo "$first" | grep -Eq 'gpg \(GnuPG\) [0-9]+\.[0-9]+\.[0-9]+'
