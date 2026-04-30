#!/usr/bin/env bash
# @testcase: usage-bash-case-conversion
# @title: bash parameter case conversion
# @description: Exercises ${var^^} upper-case and ${var,,} lower-case parameter expansions and validates exact results.
# @timeout: 120
# @tags: usage, bash
# @client: bash

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bash-case-conversion"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

value='Hello World'
upper="${value^^}"
lower="${value,,}"
test "$upper" = 'HELLO WORLD'
test "$lower" = 'hello world'

mixed='aBcDeF'
test "${mixed^^}" = 'ABCDEF'
test "${mixed,,}" = 'abcdef'
