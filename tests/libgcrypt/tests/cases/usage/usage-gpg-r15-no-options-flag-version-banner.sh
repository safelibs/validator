#!/usr/bin/env bash
# @testcase: usage-gpg-r15-no-options-flag-version-banner
# @title: gpg --no-options --version still emits the libgcrypt-aware version banner
# @description: Runs gpg --no-options --version against an ephemeral GNUPGHOME, asserting that even with options-file processing disabled the banner is still produced and contains the literal "gpg (GnuPG)" prefix and a "libgcrypt" line — confirming gpg honors --no-options without dropping its libgcrypt runtime banner.
# @timeout: 60
# @tags: usage, gpg, no-options, version, libgcrypt, r15
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg --no-options --version >"$tmpdir/out" 2>&1

LC_ALL=C grep -E '^gpg \(GnuPG\)' "$tmpdir/out" >/dev/null || {
  echo 'banner missing "gpg (GnuPG)" prefix' >&2
  cat "$tmpdir/out" >&2
  exit 1
}
LC_ALL=C grep -F 'libgcrypt' "$tmpdir/out" >/dev/null || {
  echo 'banner missing libgcrypt line' >&2
  cat "$tmpdir/out" >&2
  exit 1
}
