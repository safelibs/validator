#!/usr/bin/env bash
# @testcase: usage-gio-r13-info-filesystem-readonly-attribute
# @title: gio info -a queries a filesystem::readonly attribute via the filesystem namespace
# @description: Calls gio info with --attributes=filesystem::readonly on a probe directory and asserts the attribute key appears in the output with a boolean TRUE/FALSE value.
# @timeout: 60
# @tags: usage, gio, filesystem, attributes
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/probe"
gio info --filesystem -a 'filesystem::readonly' "$tmpdir/probe" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" 'filesystem::readonly:'
# The attribute value must be the boolean TRUE or FALSE token.
if ! grep -E 'filesystem::readonly:[[:space:]]*(TRUE|FALSE)' "$tmpdir/out" >/dev/null; then
  printf 'expected filesystem::readonly to expose a TRUE/FALSE value\n' >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
