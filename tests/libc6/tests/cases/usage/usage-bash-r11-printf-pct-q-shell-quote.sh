#!/usr/bin/env bash
# @testcase: usage-bash-r11-printf-pct-q-shell-quote
# @title: bash printf %q escapes shell metacharacters via libc string handling
# @description: Uses bash builtin printf %q to shell-quote a string containing spaces single-quotes and dollar signs and verifies the result re-evaluates to the original via eval, exercising bash quoting that goes through libc string routines.
# @timeout: 60
# @tags: usage, bash, printf
# @client: bash

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

LC_ALL=C
input="hello world 'quoted' \$var"
quoted=$(printf '%q' "$input")
roundtrip=$(eval "printf '%s' $quoted")
[[ "$roundtrip" == "$input" ]]
