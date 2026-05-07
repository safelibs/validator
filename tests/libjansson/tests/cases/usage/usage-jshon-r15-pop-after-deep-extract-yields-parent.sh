#!/usr/bin/env bash
# @testcase: usage-jshon-r15-pop-after-deep-extract-yields-parent
# @title: jshon -e a -e b -e c -p -k lists parent-of-c keys after pop
# @description: Pipes a three-level nested object through jshon -e a -e b -e c -p -k, popping back to the b-level container, and verifies the listed keys are exactly the keys of b ("c"), exercising pop after a deep extract chain.
# @timeout: 30
# @tags: usage, json, cli, pop
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '{"a":{"b":{"c":"leaf"}}}' | jshon -e a -e b -e c -p -k >"$tmpdir/keys"
diff -u <(printf 'c\n') "$tmpdir/keys"
