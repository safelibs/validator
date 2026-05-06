#!/usr/bin/env bash
# @testcase: usage-readstat-r10-version-flag-stdout
# @title: readstat -v prints only the version line on stdout
# @description: Invokes readstat with the -v flag and verifies the binary prints exactly one stdout line of the form "ReadStat version X.Y.Z" with stderr empty and exits zero, distinguishing the version-only output from the full help banner emitted with no arguments.
# @timeout: 60
# @tags: usage, csv, cli, version
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

readstat -v >"$tmpdir/stdout" 2>"$tmpdir/stderr"

# Stdout must contain a single line matching the version banner shape.
line_count=$(wc -l <"$tmpdir/stdout")
if [[ "$line_count" != "1" ]]; then
  printf 'expected 1 stdout line for -v, got %s\n' "$line_count" >&2
  cat "$tmpdir/stdout" >&2
  exit 1
fi

if ! grep -E '^ReadStat version [0-9]+\.[0-9]+\.[0-9]+$' "$tmpdir/stdout" >/dev/null; then
  printf 'stdout did not match version-line shape\n' >&2
  cat "$tmpdir/stdout" >&2
  exit 1
fi

# Stderr must be empty for the version flag.
if [[ -s "$tmpdir/stderr" ]]; then
  printf 'expected empty stderr for -v, got:\n' >&2
  cat "$tmpdir/stderr" >&2
  exit 1
fi

# The version flag must not include any of the banner usage instructions.
for phrase in 'View a file' 'Convert a file' 'metadata.json'; do
  if grep -F -- "$phrase" "$tmpdir/stdout" >/dev/null; then
    printf 'stdout unexpectedly contained banner phrase: %s\n' "$phrase" >&2
    cat "$tmpdir/stdout" >&2
    exit 1
  fi
done
