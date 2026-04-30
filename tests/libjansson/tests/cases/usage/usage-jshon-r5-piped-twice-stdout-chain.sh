#!/usr/bin/env bash
# @testcase: usage-jshon-r5-piped-twice-stdout-chain
# @title: jshon piped twice via stdout chain
# @description: Pipes the output of one jshon invocation (extracting a sub-document) into a second jshon invocation, verifying that an emitted JSON sub-document is itself a valid input to jshon and that downstream extraction returns the expected leaf.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r5-piped-twice-stdout-chain"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"outer":{"inner":{"leaf":"chained-ok","other":42}},"sibling":"ignored"}'

# First stage emits the inner sub-object as JSON; second stage extracts leaf.
printf '%s' "$json" \
  | jshon -e outer -e inner \
  | jshon -e leaf -u >"$tmpdir/leaf"

if ! grep -Fxq -- 'chained-ok' "$tmpdir/leaf"; then
  printf 'expected chained-ok after stdout pipe chain, got:\n' >&2
  cat "$tmpdir/leaf" >&2
  exit 1
fi

# Confirm intermediate sub-document is itself valid jshon input by listing keys.
printf '%s' "$json" \
  | jshon -e outer -e inner \
  | jshon -k >"$tmpdir/keys"

for key in leaf other; do
  if ! grep -Fxq -- "$key" "$tmpdir/keys"; then
    printf 'expected key %s after pipe chain, got:\n' "$key" >&2
    cat "$tmpdir/keys" >&2
    exit 1
  fi
done

count=$(wc -l <"$tmpdir/keys")
if [[ "$count" -ne 2 ]]; then
  printf 'expected 2 keys in piped sub-document, got %s:\n' "$count" >&2
  cat "$tmpdir/keys" >&2
  exit 1
fi
