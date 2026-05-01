#!/usr/bin/env bash
# @testcase: usage-jshon-r8-null-delimiter-unstring
# @title: jshon -0 emits NUL-delimited unstring output instead of newline-delimited
# @description: Maps -u across an array of strings with and without -0 and inspects the raw byte stream, asserting that without -0 jshon separates entries with 0x0a newlines while with -0 the same payload is separated with 0x00 null bytes, and that xargs -0 can recover the values intact when piped through the null-delimited form.
# @timeout: 120
# @tags: usage, json, jshon
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-jshon-r8-null-delimiter-unstring"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

json='["alpha","beta","gamma"]'

# Default newline-delimited unstring across the array.
printf '%s' "$json" | jshon -a -u >"$tmpdir/nl.bin"
nl_bytes=$(wc -c <"$tmpdir/nl.bin")
nl_count=$(tr -dc '\n' <"$tmpdir/nl.bin" | wc -c)
nul_count_nl=$(tr -dc '\0' <"$tmpdir/nl.bin" | wc -c)
if [[ "$nl_count" -ne 3 ]]; then
  printf 'expected 3 newline separators by default, got %s in %s bytes\n' "$nl_count" "$nl_bytes" >&2
  exit 1
fi
if [[ "$nul_count_nl" -ne 0 ]]; then
  printf 'expected zero NUL bytes by default, got %s\n' "$nul_count_nl" >&2
  exit 1
fi

# -0 swaps the per-record terminator from newline to NUL.
printf '%s' "$json" | jshon -0 -a -u >"$tmpdir/nul.bin"
nul_bytes=$(wc -c <"$tmpdir/nul.bin")
nul_count=$(tr -dc '\0' <"$tmpdir/nul.bin" | wc -c)
nl_count_nul=$(tr -dc '\n' <"$tmpdir/nul.bin" | wc -c)
if [[ "$nul_count" -ne 3 ]]; then
  printf 'expected 3 NUL separators with -0, got %s in %s bytes\n' "$nul_count" "$nul_bytes" >&2
  exit 1
fi
if [[ "$nl_count_nul" -ne 0 ]]; then
  printf 'expected zero newlines with -0, got %s\n' "$nl_count_nul" >&2
  exit 1
fi

# xargs -0 reads the NUL stream back into three arguments.
mapfile -t recovered < <(xargs -0 -n1 printf '%s\n' <"$tmpdir/nul.bin")
if [[ "${#recovered[@]}" -ne 3 ]]; then
  printf 'expected xargs -0 to produce 3 args, got %s\n' "${#recovered[@]}" >&2
  printf '%s\n' "${recovered[@]}" >&2
  exit 1
fi
expected=(alpha beta gamma)
for i in 0 1 2; do
  if [[ "${recovered[$i]}" != "${expected[$i]}" ]]; then
    printf 'recovered[%s] expected %s, got %s\n' "$i" "${expected[$i]}" "${recovered[$i]}" >&2
    exit 1
  fi
done
