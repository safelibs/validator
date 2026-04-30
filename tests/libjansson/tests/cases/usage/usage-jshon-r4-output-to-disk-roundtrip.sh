#!/usr/bin/env bash
# @testcase: usage-jshon-r4-output-to-disk-roundtrip
# @title: jshon manipulated output round-trips through disk
# @description: Deletes a key with jshon and redirects the resulting JSON to a file, then reopens the file with jshon -F to verify the deletion survived the disk round-trip and that surviving keys still resolve to their original values.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r4-output-to-disk-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='{"alpha":"first","beta":"second","gamma":"third"}'

# Step 1: produce a modified document on disk.
printf '%s' "$json" | jshon -d beta >"$tmpdir/modified.json"

# File must be non-empty and parseable.
if [[ ! -s "$tmpdir/modified.json" ]]; then
  printf 'expected non-empty modified.json\n' >&2
  exit 1
fi

# Step 2: re-read with jshon -F and check keys.
jshon -F "$tmpdir/modified.json" -k >"$tmpdir/keys"

count=$(wc -l <"$tmpdir/keys")
if [[ "$count" -ne 2 ]]; then
  printf 'expected 2 keys after disk round-trip, got %s:\n' "$count" >&2
  cat "$tmpdir/keys" >&2
  exit 1
fi

if grep -Fxq -- 'beta' "$tmpdir/keys"; then
  printf 'expected beta to be absent after disk round-trip, got:\n' >&2
  cat "$tmpdir/keys" >&2
  exit 1
fi

for key in alpha gamma; do
  if ! grep -Fxq -- "$key" "$tmpdir/keys"; then
    printf 'expected key %s after disk round-trip, got:\n' "$key" >&2
    cat "$tmpdir/keys" >&2
    exit 1
  fi
done

# Step 3: surviving values must still resolve from the on-disk file.
jshon -F "$tmpdir/modified.json" -e alpha -u >"$tmpdir/alpha"
if ! grep -Fxq -- 'first' "$tmpdir/alpha"; then
  printf 'expected alpha=first after round-trip, got:\n' >&2
  cat "$tmpdir/alpha" >&2
  exit 1
fi

jshon -F "$tmpdir/modified.json" -e gamma -u >"$tmpdir/gamma"
if ! grep -Fxq -- 'third' "$tmpdir/gamma"; then
  printf 'expected gamma=third after round-trip, got:\n' >&2
  cat "$tmpdir/gamma" >&2
  exit 1
fi
