#!/usr/bin/env bash
# @testcase: hmac-sha256-smoke
# @title: libgcrypt HMAC digest
# @description: Computes an HMAC through gcry_md_open with the HMAC flag.
# @timeout: 120
# @tags: api, crypto

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="hmac-sha256-smoke"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

compile_and_run() {
  local needle=$1
  cat >"$tmpdir/t.c"
  gcc "$tmpdir/t.c" -o "$tmpdir/t" $(libgcrypt-config --cflags --libs)
  "$tmpdir/t" >"$tmpdir/out"
  validator_assert_contains "$tmpdir/out" "$needle"
}

compile_and_run 'hmac=' <<'C'
#include <gcrypt.h>
#include <stdio.h>
#include <string.h>
int main(void) {
    gcry_md_hd_t hd;
    const char *key = "validator-key";
    const char *msg = "payload";
    gcry_check_version(NULL);
    if (gcry_md_open(&hd, GCRY_MD_SHA256, GCRY_MD_FLAG_HMAC)) return 1;
    if (gcry_md_setkey(hd, key, strlen(key))) return 2;
    gcry_md_write(hd, msg, strlen(msg));
    unsigned char *digest = gcry_md_read(hd, GCRY_MD_SHA256);
    printf("hmac=");
    for (int i = 0; i < 6; ++i) printf("%02x", digest[i]);
    printf("\n");
    gcry_md_close(hd);
    return 0;
}
C
