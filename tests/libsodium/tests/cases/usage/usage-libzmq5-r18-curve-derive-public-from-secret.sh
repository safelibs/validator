#!/usr/bin/env bash
# @testcase: usage-libzmq5-r18-curve-derive-public-from-secret
# @title: ZeroMQ zmq_curve_public derives the same public key from a CURVE secret key
# @description: Compiles a tiny C program that calls zmq_curve_keypair, captures its public key, then independently re-derives the public key from the same secret key with zmq_curve_public into a fresh buffer, asserts the call returns 0, asserts both derived public-key strings are 40-character Z85 strings, and asserts they are byte-for-byte identical (libsodium scalarmult-base path).
# @timeout: 180
# @tags: usage, zmq, curve, derive, r18
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
    char pub_kp[41] = {0};
    char sec[41]    = {0};
    char pub_dv[41] = {0};

    if (zmq_curve_keypair(pub_kp, sec) != 0) {
        fprintf(stderr, "zmq_curve_keypair failed\n");
        return 1;
    }
    if (zmq_curve_public(pub_dv, sec) != 0) {
        fprintf(stderr, "zmq_curve_public failed\n");
        return 2;
    }
    if (strlen(pub_kp) != 40 || strlen(pub_dv) != 40) {
        fprintf(stderr, "lengths kp=%zu dv=%zu\n", strlen(pub_kp), strlen(pub_dv));
        return 3;
    }
    if (strcmp(pub_kp, pub_dv) != 0) {
        fprintf(stderr, "derived public != keypair public\n");
        return 4;
    }
    puts("ok");
    return 0;
}
C

gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs libzmq)
"$tmpdir/t"
