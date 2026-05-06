#!/usr/bin/env bash
# @testcase: usage-pngquant-r10-version-flag
# @title: pngquant --version reports a 2.x build
# @description: Invokes pngquant --version and verifies the banner advertises a 2.x release with parenthesised release date.
# @timeout: 30
# @tags: usage, png, pngquant
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

pngquant --version >"$tmpdir/out.txt" 2>&1

grep -Eq '^2\.[0-9]+(\.[0-9]+)? \(' "$tmpdir/out.txt" || {
  printf 'unexpected --version banner:\n' >&2
  cat "$tmpdir/out.txt" >&2
  exit 1
}
