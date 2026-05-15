#!/usr/bin/env bash
# @testcase: usage-libzmq5-r20-z85-encode-length-multiple-of-four
# @title: ZeroMQ zmq_z85_encode of 8 binary bytes yields a 10-character Z85 string
# @description: Compiles a C program that encodes 8 input bytes with zmq_z85_encode and asserts the returned buffer string-length is exactly 10 (8/4*5), confirming libsodium-backed Z85 alphabet expansion follows the documented 4-bytes-to-5-chars ratio.
# @timeout: 180
# @tags: usage, zmq, z85, encode, r20
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
    uint8_t in[8] = {0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08};
    char out[16] = {0};
    if (zmq_z85_encode(out, in, sizeof(in)) == NULL) return 1;
    if (strlen(out) != 10) {
        fprintf(stderr, "len=%zu out=%s\n", strlen(out), out);
        return 2;
    }
    printf("ok z85=%s\n", out);
    return 0;
}
C

gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs libzmq)
"$tmpdir/t" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'ok z85='
