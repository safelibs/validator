#!/usr/bin/env bash
# @testcase: usage-jshon-missing-key-error-exit
# @title: jshon nonexistent key exit status
# @description: Confirms jshon -e on an absent object key exits with a nonzero status while a present key returns success.
# @timeout: 120
# @tags: usage, json
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-missing-key-error-exit"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"present":"yes","other":1}'

# Present key: exit 0.
printf '%s' "$json" | jshon -e present -u >"$tmpdir/present"
validator_assert_contains "$tmpdir/present" 'yes'

# Missing key: nonzero exit. Disable -e inside the subshell to capture rc.
set +e
printf '%s' "$json" | jshon -e absent -u >"$tmpdir/absent" 2>"$tmpdir/err"
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  printf 'expected jshon -e absent to fail, got rc=%s\n' "$rc" >&2
  exit 1
fi
