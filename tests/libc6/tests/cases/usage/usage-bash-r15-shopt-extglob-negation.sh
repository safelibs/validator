#!/usr/bin/env bash
# @testcase: usage-bash-r15-shopt-extglob-negation
# @title: bash shopt -s extglob enables !(...) negation pattern in pathname expansion
# @description: Enables the extglob shell option, builds a directory of three files (a.txt, b.txt, c.log), runs an extglob !(*.log) pathname expansion under LC_ALL=C, sorts the result and asserts only a.txt and b.txt are matched (the .log file excluded) — exercising bash's libc-backed glob with extended-glob semantics.
# @timeout: 60
# @tags: usage, bash, extglob, libc, r15
# @client: bash

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/d"
: >"$tmpdir/d/a.txt"
: >"$tmpdir/d/b.txt"
: >"$tmpdir/d/c.log"

# Run the extglob !(*.log) pattern in a fresh bash invocation that has extglob
# enabled at parse time (parent script may not have extglob set when this file
# is sourced/parsed; -O extglob ensures the extended-glob expression is
# accepted by the parser).
matches_raw=$(bash -O extglob -c '
  cd "$1" || exit 1
  LC_ALL=C printf "%s\n" !(*.log) | LC_ALL=C sort
' _ "$tmpdir/d")

mapfile -t matches <<<"$matches_raw"

[[ "${#matches[@]}" -eq 2 ]]
[[ "${matches[0]}" == "a.txt" ]]
[[ "${matches[1]}" == "b.txt" ]]
