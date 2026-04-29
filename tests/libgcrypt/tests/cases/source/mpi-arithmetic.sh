#!/usr/bin/env bash
# @testcase: mpi-arithmetic
# @title: libgcrypt MPI arithmetic
# @description: Adds integers through the multi-precision integer API and prints the result.
# @timeout: 120
# @tags: api, mpi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="mpi-arithmetic"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

compile_and_run() {
  local needle=$1
  cat >"$tmpdir/t.c"
  gcc "$tmpdir/t.c" -o "$tmpdir/t" $(libgcrypt-config --cflags --libs)
  "$tmpdir/t" >"$tmpdir/out"
  validator_assert_contains "$tmpdir/out" "$needle"
}

compile_and_run 'mpi=42' <<'C'
#include <gcrypt.h>
#include <stdio.h>
int main(void) {
    gcry_mpi_t value = gcry_mpi_new(0);
    unsigned int result = 0;
    gcry_mpi_set_ui(value, 40);
    gcry_mpi_add_ui(value, value, 2);
    if (gcry_mpi_get_ui(&result, value)) return 1;
    printf("mpi=%u\n", result);
    gcry_mpi_release(value);
    return 0;
}
C
