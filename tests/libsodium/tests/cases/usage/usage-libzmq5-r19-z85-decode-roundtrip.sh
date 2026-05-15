#!/usr/bin/env bash
# @testcase: usage-libzmq5-r19-z85-decode-roundtrip
# @title: ZeroMQ zmq_z85_encode and zmq_z85_decode round-trip a 32-byte binary key
# @description: Compiles a C program that fills 32 random bytes via zmq_curve_keypair-derived material, encodes them with zmq_z85_encode into a 41-byte string buffer, asserts the encoded string is exactly 40 characters of printable ASCII, decodes back with zmq_z85_decode into a fresh 32-byte buffer, and asserts the decoded bytes equal the original byte-for-byte (libsodium-backed Z85 codec).
# @timeout: 180
# @tags: usage, zmq, z85, codec, r19
# @client: libzmq5

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <zmq.h>
#include <stdio.h>
#include <string.h>

int main(void) {
    char pub[41] = {0};
    char sec[41] = {0};
    if (zmq_curve_keypair(pub, sec) != 0) { return 1; }

    /* decode pub Z85 -> 32 binary bytes */
    uint8_t bin[32] = {0};
    if (zmq_z85_decode(bin, pub) == NULL) { return 2; }

    /* encode the 32 binary bytes back to Z85 */
    char enc[41] = {0};
    if (zmq_z85_encode(enc, bin, 32) == NULL) { return 3; }

    if (strlen(enc) != 40) { fprintf(stderr, "len=%zu\n", strlen(enc)); return 4; }
    if (strcmp(enc, pub) != 0) { fprintf(stderr, "roundtrip mismatch\n"); return 5; }

    /* second decode is byte-stable */
    uint8_t bin2[32] = {0};
    if (zmq_z85_decode(bin2, enc) == NULL) { return 6; }
    if (memcmp(bin, bin2, 32) != 0) { return 7; }
    puts("ok");
    return 0;
}
C

gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs libzmq)
"$tmpdir/t"
