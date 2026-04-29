#!/usr/bin/env bash
# @testcase: locale-collation
# @title: glibc locale collation
# @description: Sets the C.UTF-8 locale and compares strings through strcoll.
# @timeout: 120
# @tags: api, locale

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="locale-collation"
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

compile_and_run 'locale=C.UTF-8' <<'C'
#include <locale.h>
#include <stdio.h>
#include <string.h>
int main(void) {
    const char *locale = setlocale(LC_ALL, "C.UTF-8");
    int cmp = strcoll("alpha", "beta");
    printf("locale=%s cmp=%d\n", locale ? locale : "missing", cmp < 0);
    return locale && cmp < 0 ? 0 : 1;
}
C
