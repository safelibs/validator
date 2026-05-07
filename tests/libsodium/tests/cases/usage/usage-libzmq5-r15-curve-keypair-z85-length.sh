#!/usr/bin/env bash
# @testcase: usage-libzmq5-r15-curve-keypair-z85-length
# @title: ZeroMQ zmq_curve_keypair returns 40-character Z85-encoded public and secret keys
# @description: Compiles a single-process C program that calls zmq_curve_keypair into 41-byte buffers, asserts the call returns 0 (success), the resulting public and secret strings are exactly 40 Z85 characters each (libsodium-derived 32-byte keys, base85-encoded), and that the public key string differs from the secret key string.
# @timeout: 180
# @tags: usage, zmq, curve, z85, r15
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
    char pubkey[41] = {0};
    char seckey[41] = {0};

    int rc = zmq_curve_keypair(pubkey, seckey);
    if (rc != 0) {
        fprintf(stderr, "zmq_curve_keypair rc=%d\n", rc);
        return 1;
    }

    if (strlen(pubkey) != 40) {
        fprintf(stderr, "pubkey len %zu != 40\n", strlen(pubkey));
        return 2;
    }
    if (strlen(seckey) != 40) {
        fprintf(stderr, "seckey len %zu != 40\n", strlen(seckey));
        return 3;
    }
    if (strcmp(pubkey, seckey) == 0) {
        fprintf(stderr, "public and secret keys are identical\n");
        return 4;
    }

    puts("ok");
    return 0;
}
C

gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs libzmq)
"$tmpdir/t"
