#!/usr/bin/env bash
# @testcase: aes-ctr-roundtrip
# @title: libgcrypt AES CTR round trip
# @description: Encrypts and decrypts a buffer through the AES-128 CTR cipher API.
# @timeout: 120
# @tags: api, crypto

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="aes-ctr-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

compile_and_run() {
  local needle=$1
  cat >"$tmpdir/t.c"
  gcc "$tmpdir/t.c" -o "$tmpdir/t" $(libgcrypt-config --cflags --libs)
  "$tmpdir/t" >"$tmpdir/out"
  validator_assert_contains "$tmpdir/out" "$needle"
}

compile_and_run 'plain=validator-data' <<'C'
#include <gcrypt.h>
#include <stdio.h>
#include <string.h>
static int crypt(unsigned char *buf) {
    gcry_cipher_hd_t hd;
    unsigned char key[16] = {0};
    unsigned char ctr[16] = {0};
    if (gcry_cipher_open(&hd, GCRY_CIPHER_AES128, GCRY_CIPHER_MODE_CTR, 0)) return 1;
    if (gcry_cipher_setkey(hd, key, sizeof key)) return 2;
    if (gcry_cipher_setctr(hd, ctr, sizeof ctr)) return 3;
    if (gcry_cipher_encrypt(hd, buf, 16, NULL, 0)) return 4;
    gcry_cipher_close(hd);
    return 0;
}
int main(void) {
    unsigned char buf[16] = "validator-data";
    gcry_check_version(NULL);
    if (crypt(buf) || crypt(buf)) return 1;
    printf("plain=%s\n", buf);
    return strcmp((char *)buf, "validator-data") == 0 ? 0 : 2;
}
C
