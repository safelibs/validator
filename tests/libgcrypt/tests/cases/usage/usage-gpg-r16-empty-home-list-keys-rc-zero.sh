#!/usr/bin/env bash
# @testcase: usage-gpg-r16-empty-home-list-keys-rc-zero
# @title: gpg --list-keys on a fresh GNUPGHOME exits zero with empty stdout
# @description: Creates a brand-new GNUPGHOME, runs gpg --batch --list-keys, asserts the exit status is zero and the captured stdout is empty (no key records appear when the public keyring is freshly created), a smoke check distinct from the r15 colons-count variant.
# @timeout: 60
# @tags: usage, gpg, list-keys, empty-home
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg --batch --list-keys >"$tmpdir/out" 2>"$tmpdir/err"

if [[ -s "$tmpdir/out" ]]; then
  printf 'expected empty stdout, got:\n' >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
