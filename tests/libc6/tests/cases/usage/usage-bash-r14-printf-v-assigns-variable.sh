#!/usr/bin/env bash
# @testcase: usage-bash-r14-printf-v-assigns-variable
# @title: bash printf -v writes formatted output to a named variable
# @description: Uses printf -v to assign a formatted string with width and zero-padding directly into a shell variable (no fork, no temporary file), and asserts the variable holds the expected libc-formatted bytes byte-for-byte.
# @timeout: 60
# @tags: usage, bash, printf, libc
# @client: bash

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Format an integer with libc-backed %05d into a variable, no subshell.
result=''
printf -v result 'id=%05d:%s' 42 'alpha'
[[ "$result" == "id=00042:alpha" ]]

# Re-assignment overwrites cleanly with a different format.
printf -v result '%-6s|%6s' 'lo' 'hi'
[[ "$result" == "lo    |    hi" ]]
