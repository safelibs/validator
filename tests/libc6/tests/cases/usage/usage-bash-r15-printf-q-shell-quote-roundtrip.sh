#!/usr/bin/env bash
# @testcase: usage-bash-r15-printf-q-shell-quote-roundtrip
# @title: bash printf %q quotes a string with shell metacharacters into a re-parseable form
# @description: Uses bash printf %q to quote a string containing spaces, single quotes, and a dollar sign into a shell-safe representation, asserts the encoded form differs from the input, and round-trips it back to the original byte-for-byte by feeding the encoded form to eval as a single-word echo argument.
# @timeout: 60
# @tags: usage, bash, printf, libc, r15
# @client: bash

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raw=$'hello world '\''with quotes'\'' and $dollar'

quoted=$(printf '%q' "$raw")

# %q must produce a non-empty representation different from the raw bytes.
[[ -n "$quoted" ]]
[[ "$quoted" != "$raw" ]]

# Round-trip: eval echoing the quoted form must reproduce the original.
roundtrip=$(eval "printf '%s' $quoted")
[[ "$roundtrip" == "$raw" ]]
