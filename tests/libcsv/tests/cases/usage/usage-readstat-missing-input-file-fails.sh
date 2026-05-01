#!/usr/bin/env bash
# @testcase: usage-readstat-missing-input-file-fails
# @title: readstat reports diagnostic on a non-existent input file
# @description: Asks readstat to convert from an input path that does not exist to a CSV output, captures stderr, and verifies the diagnostic mentions an unable-to-open error and refuses to write any rows of output content beyond an empty placeholder, locking in the failure pathway for missing inputs.
# @timeout: 60
# @tags: usage, csv, error
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

readstat "$tmpdir/does-not-exist.dta" "$tmpdir/out.csv" >"$tmpdir/stdout" 2>"$tmpdir/stderr" || true

cat "$tmpdir/stdout" "$tmpdir/stderr" >"$tmpdir/all"

# Some diagnostic must reference the missing input.
if ! grep -F 'Unable to open file' "$tmpdir/all" >/dev/null; then
  printf 'expected an Unable-to-open diagnostic for missing input\n' >&2
  cat "$tmpdir/all" >&2
  exit 1
fi

# If an output CSV was produced, it must be empty (no data rows leaked).
if [[ -f "$tmpdir/out.csv" ]]; then
  size=$(wc -c <"$tmpdir/out.csv")
  if (( size > 0 )); then
    printf 'unexpected non-empty output for missing input: %s bytes\n' "$size" >&2
    cat "$tmpdir/out.csv" >&2
    exit 1
  fi
fi
