#!/usr/bin/env bash
# @testcase: usage-bash-substring-expansion
# @title: bash substring expansion
# @description: Expands a bash substring and verifies the sliced text is returned correctly.
# @timeout: 180
# @tags: usage, shell
# @client: bash

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bash-substring-expansion"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

bash -lc 'text=validator; printf "%s\n" "${text:1:4}"' >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'alid'
