#!/usr/bin/env bash
# @testcase: usage-jshon-r11-version-flag-yyyymmdd
# @title: jshon --version emits an 8-digit YYYYMMDD release date
# @description: Invokes jshon --version and verifies stdout is a single 8-digit YYYYMMDD timestamp with stderr empty and exit zero, exercising the documented version banner format.
# @timeout: 30
# @tags: usage, json, cli, version
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

jshon --version >"$tmpdir/out" 2>"$tmpdir/err"
[[ -s "$tmpdir/out" ]] || { printf 'expected non-empty stdout\n' >&2; exit 1; }
[[ ! -s "$tmpdir/err" ]] || { printf 'unexpected stderr:\n' >&2; cat "$tmpdir/err" >&2; exit 1; }

ver=$(cat "$tmpdir/out")
[[ "$ver" =~ ^[0-9]{8}$ ]] || { printf 'expected YYYYMMDD, got %q\n' "$ver" >&2; exit 1; }
