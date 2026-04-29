#!/usr/bin/env bash
# @testcase: nonce-generation
# @title: libgcrypt nonce generation
# @description: Fills a nonce buffer with gcry_create_nonce and verifies it is not all zero bytes.
# @timeout: 120
# @tags: api, random

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="nonce-generation"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

compile_and_run() {
  local needle=$1
  cat >"$tmpdir/t.c"
  gcc "$tmpdir/t.c" -o "$tmpdir/t" $(libgcrypt-config --cflags --libs)
  "$tmpdir/t" >"$tmpdir/out"
  validator_assert_contains "$tmpdir/out" "$needle"
}

compile_and_run 'nonzero=1' <<'C'
#include <gcrypt.h>
#include <stdio.h>
int main(void) {
    unsigned char nonce[16] = {0};
    int nonzero = 0;
    gcry_check_version(NULL);
    gcry_create_nonce(nonce, sizeof nonce);
    for (int i = 0; i < 16; ++i) nonzero |= nonce[i] != 0;
    printf("nonzero=%d\n", nonzero);
    return nonzero ? 0 : 1;
}
C
