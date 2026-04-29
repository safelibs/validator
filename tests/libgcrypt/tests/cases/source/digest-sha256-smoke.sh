#!/usr/bin/env bash
# @testcase: digest-sha256-smoke
# @title: libgcrypt SHA-256 digest
# @description: Computes a SHA-256 digest with gcry_md_hash_buffer and verifies the known prefix.
# @timeout: 120
# @tags: api, crypto

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="digest-sha256-smoke"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

compile_and_run() {
  local needle=$1
  cat >"$tmpdir/t.c"
  gcc "$tmpdir/t.c" -o "$tmpdir/t" $(libgcrypt-config --cflags --libs)
  "$tmpdir/t" >"$tmpdir/out"
  validator_assert_contains "$tmpdir/out" "$needle"
}

compile_and_run 'sha256=ba7816bf' <<'C'
#include <gcrypt.h>
#include <stdio.h>
int main(void) {
    unsigned char digest[32];
    gcry_check_version(NULL);
    gcry_md_hash_buffer(GCRY_MD_SHA256, digest, "abc", 3);
    printf("sha256=");
    for (int i = 0; i < 4; ++i) printf("%02x", digest[i]);
    printf("\n");
    return digest[0] == 0xba ? 0 : 1;
}
C
