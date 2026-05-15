#!/usr/bin/env bash
# @testcase: usage-exif-r20-cli-help-mentions-output-flag
# @title: exif --help help text mentions the --output flag
# @description: Runs exif --help, merges stdout and stderr, and asserts the captured help text mentions the "--output" flag - locking in libexif's help banner advertising the --output option.
# @timeout: 30
# @tags: usage, exif, help, output, r20
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

exif --help >"$tmpdir/help" 2>&1 || true
validator_assert_contains "$tmpdir/help" '--output'
