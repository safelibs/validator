#!/usr/bin/env bash
# @testcase: usage-gpg-list-config-version
# @title: gpg --list-config reports version line
# @description: Runs gpg --with-colons --list-config and asserts a cfg:version: record is emitted with a non-empty version string.
# @timeout: 120
# @tags: usage, gpg, config
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gpg-list-config-version"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupghome"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg --with-colons --list-config >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'cfg:version:'

ver=$(grep -E '^cfg:version:' "$tmpdir/out" | head -n 1 | awk -F: '{print $3}')
test -n "$ver"
echo "$ver" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+'
