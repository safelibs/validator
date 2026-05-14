#!/usr/bin/env bash
# @testcase: usage-gio-r17-cat-reads-fixture-payload-verbatim
# @title: gio cat reads a tmpdir fixture and prints the payload verbatim
# @description: Writes a known ASCII payload "r17-gio-cat-marker" into a tmpdir file and asserts gio cat prints the exact payload string on stdout, exercising the basic local-file read path through the gio CLI distinct from gio cat tests that pipe URIs or empty files.
# @timeout: 60
# @tags: usage, gio, cat
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r17-gio-cat-marker\n' >"$tmpdir/payload.txt"
gio cat "$tmpdir/payload.txt" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'r17-gio-cat-marker'
