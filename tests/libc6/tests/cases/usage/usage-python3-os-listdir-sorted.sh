#!/usr/bin/env bash
# @testcase: usage-python3-os-listdir-sorted
# @title: python3 os.listdir sorted
# @description: Lists a directory through Python os.listdir and verifies the sorted entry names produced by the runtime.
# @timeout: 180
# @tags: usage, python, filesystem
# @client: python3-minimal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-os-listdir-sorted"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/lst"
: >"$tmpdir/lst/alpha.txt"
: >"$tmpdir/lst/beta.txt"
DIR_PATH="$tmpdir/lst" python3 >"$tmpdir/out" <<'PY'
import os
print(','.join(sorted(os.listdir(os.environ['DIR_PATH']))))
PY
validator_assert_contains "$tmpdir/out" 'alpha.txt,beta.txt'
