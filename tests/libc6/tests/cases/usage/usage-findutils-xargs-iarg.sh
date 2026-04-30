#!/usr/bin/env bash
# @testcase: usage-findutils-xargs-iarg
# @title: findutils xargs -I substitutes per item
# @description: Pipes find output through xargs -I{} -n1 to run a per-file command and verifies exact transformed output.
# @timeout: 180
# @tags: usage, findutils
# @client: findutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-findutils-xargs-iarg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/tree"
: >"$tmpdir/tree/alpha.txt"
: >"$tmpdir/tree/beta.txt"
: >"$tmpdir/tree/gamma.txt"

find "$tmpdir/tree" -maxdepth 1 -type f -name '*.txt' -printf '%f\n' \
  | sort \
  | xargs -I{} -n1 printf 'item=%s\n' {} >"$tmpdir/out"

expected=$(printf 'item=alpha.txt\nitem=beta.txt\nitem=gamma.txt\n')
actual=$(cat "$tmpdir/out")
test "$actual" = "$expected"

line_count=$(wc -l <"$tmpdir/out")
test "$line_count" -eq 3
