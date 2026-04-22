#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

compile_and_run() {
  local needle=$1
  cat >"$tmpdir/t.c"
  gcc "$tmpdir/t.c" -o "$tmpdir/t" $(libgcrypt-config --cflags --libs)
  "$tmpdir/t" >"$tmpdir/out"
  validator_assert_contains "$tmpdir/out" "$needle"
}

case "$case_id" in
  digest-sha256-smoke)
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
    ;;
  hmac-sha256-smoke)
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
    ;;
  aes-ctr-roundtrip)
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
    ;;
  mpi-arithmetic)
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
    ;;
  nonce-generation)
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
    ;;
  *)
    printf 'unknown libgcrypt source case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
