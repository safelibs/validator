#!/usr/bin/env bash
# @testcase: usage-exif-r9-cli-version-banner
# @title: exif --version emits identification banner
# @description: Runs exif --version and verifies the program identifies itself with a recognizable banner string and a numeric version on stdout.
# @timeout: 60
# @tags: usage, metadata, version
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

exif --version >"$tmpdir/out" 2>&1
validator_assert_contains "$tmpdir/out" 'exif'
grep -E '[0-9]+\.[0-9]+' "$tmpdir/out"
