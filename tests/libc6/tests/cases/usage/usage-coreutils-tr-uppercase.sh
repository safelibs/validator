#!/usr/bin/env bash
# @testcase: usage-coreutils-tr-uppercase
# @title: coreutils tr uppercase
# @description: Transforms lowercase text to uppercase with tr and verifies the result.
# @timeout: 180
# @tags: usage, coreutils, text
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-coreutils-tr-uppercase"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'mixed Case\n' | tr '[:lower:]' '[:upper:]' >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'MIXED CASE'
