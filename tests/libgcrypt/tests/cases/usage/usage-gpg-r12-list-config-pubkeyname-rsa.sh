#!/usr/bin/env bash
# @testcase: usage-gpg-r12-list-config-pubkeyname-rsa
# @title: gpg --list-config reports RSA in pubkeyname configuration record
# @description: Invokes gpg --with-colons --list-config in an ephemeral GNUPGHOME and verifies the cfg:pubkeyname record exists and includes RSA among the supported public-key algorithms reported by libgcrypt.
# @timeout: 60
# @tags: usage, gpg, list-config, libgcrypt
# @client: gpg

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

export GNUPGHOME="$tmpdir/gnupg"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

gpg --with-colons --list-config >"$tmpdir/out" 2>&1

validator_assert_contains "$tmpdir/out" 'cfg:pubkeyname:'

awk -F: '$1=="cfg" && $2=="pubkeyname" {print $3}' "$tmpdir/out" >"$tmpdir/algs"
grep -qi 'RSA' "$tmpdir/algs" || {
  echo 'expected RSA in cfg:pubkeyname record' >&2
  cat "$tmpdir/out" >&2
  exit 1
}
