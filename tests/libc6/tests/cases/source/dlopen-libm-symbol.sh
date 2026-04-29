#!/usr/bin/env bash
# @testcase: dlopen-libm-symbol
# @title: glibc dynamic loader symbol
# @description: Opens libm with dlopen and calls cos through dlsym.
# @timeout: 120
# @tags: api, dynamic-loader

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="dlopen-libm-symbol"
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

compile_and_run 'cos=1.0' -ldl <<'C'
#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdio.h>
int main(void) {
    void *handle = dlopen("libm.so.6", RTLD_NOW);
    if (!handle) return 1;
    double (*cos_fn)(double) = dlsym(handle, "cos");
    if (!cos_fn) return 2;
    printf("cos=%.1f\n", cos_fn(0.0));
    dlclose(handle);
    return 0;
}
C
