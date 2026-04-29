#!/usr/bin/env bash
# @testcase: stdio-string-conversion
# @title: glibc stdio string conversion
# @description: Compiles a program using snprintf and strtod from the C library.
# @timeout: 120
# @tags: api, stdio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="stdio-string-conversion"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

compile_and_run() {
  local needle=$1
  shift || true
  cat >"$tmpdir/t.c"
  gcc "$tmpdir/t.c" -o "$tmpdir/t" "$@"
  "$tmpdir/t" >"$tmpdir/out"
  validator_assert_contains "$tmpdir/out" "$needle"
}

compile_and_run 'value=42.5 text=answer' <<'C'
#include <stdio.h>
#include <stdlib.h>
int main(void) {
    char buf[64];
    double value = strtod("42.5", NULL);
    snprintf(buf, sizeof buf, "value=%.1f text=%s", value, "answer");
    puts(buf);
    return value == 42.5 ? 0 : 1;
}
C
