#!/usr/bin/env bash
# @testcase: usage-gio-r17-info-content-type-text-plain-on-txt
# @title: gio info --attributes=standard::content-type reports text/plain on a .txt file
# @description: Creates a .txt file containing a short ASCII payload and asserts gio info --attributes=standard::content-type reports text/plain for it, exercising the standard::content-type attribute on a local file with a plain-text MIME signature.
# @timeout: 60
# @tags: usage, gio, info, content-type
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r17 plain ascii payload\n' >"$tmpdir/sample.txt"
gio info --attributes='standard::content-type' "$tmpdir/sample.txt" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" 'standard::content-type:'
validator_assert_contains "$tmpdir/out" 'text/plain'
