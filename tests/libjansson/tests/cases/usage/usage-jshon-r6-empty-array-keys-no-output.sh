#!/usr/bin/env bash
# @testcase: usage-jshon-r6-empty-array-keys-no-output
# @title: jshon -k on an array fails with parse error
# @description: Anchors the type and length of an empty array via jshon -t and -l, then confirms that jshon -k on an array (which has no keys, only indices) fails with non-zero exit and emits a parse-error diagnostic to stderr - the documented behavior that callers must distinguish keys-bearing objects from arrays before requesting -k.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r6-empty-array-keys-no-output"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Empty array still has type 'array' and length 0 to anchor the document shape.
printf '%s' '[]' | jshon -t >"$tmpdir/type"
if ! grep -Fxq -- 'array' "$tmpdir/type"; then
  printf 'expected array type, got:\n' >&2
  cat "$tmpdir/type" >&2
  exit 1
fi

printf '%s' '[]' | jshon -l >"$tmpdir/len"
if ! grep -Fxq -- '0' "$tmpdir/len"; then
  printf 'expected length 0 for empty array, got:\n' >&2
  cat "$tmpdir/len" >&2
  exit 1
fi

# -k on an array must fail (arrays have indices, not keys).
set +e
printf '%s' '[]' | jshon -k >"$tmpdir/keys" 2>"$tmpdir/keys.err"
rc=$?
set -e
if (( rc == 0 )); then
  printf 'expected jshon -k on array to fail, got exit 0\n' >&2
  cat "$tmpdir/keys" >&2
  exit 1
fi

# stderr must mention the diagnostic about arrays having no keys.
if ! grep -F "no keys" "$tmpdir/keys.err" >/dev/null; then
  printf 'expected jshon stderr to mention "no keys", got:\n' >&2
  cat "$tmpdir/keys.err" >&2
  exit 1
fi

# stdout must be empty (no spurious output before the failure).
size=$(wc -c <"$tmpdir/keys")
if [[ "$size" -ne 0 ]]; then
  printf 'expected zero bytes on stdout for failed -k, got %s:\n' "$size" >&2
  od -c "$tmpdir/keys" >&2
  exit 1
fi
