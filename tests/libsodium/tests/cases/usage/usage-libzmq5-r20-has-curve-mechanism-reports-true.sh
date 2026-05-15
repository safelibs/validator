#!/usr/bin/env bash
# @testcase: usage-libzmq5-r20-has-curve-mechanism-reports-true
# @title: ZeroMQ zmq_has("curve") reports support compiled in (libsodium-backed)
# @description: Compiles a C program that calls zmq_has("curve") and asserts the return value is exactly 1, then calls zmq_has("noexistent-mech") and asserts the return is 0, confirming the libsodium-linked libzmq build advertises the CURVE security mechanism via its capability query.
# @timeout: 180
# @tags: usage, zmq, capability, curve, r20
# @client: libzmq5

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <zmq.h>
#include <stdio.h>

int main(void) {
    int has_curve = zmq_has("curve");
    if (has_curve != 1) {
        fprintf(stderr, "expected curve=1 got=%d\n", has_curve);
        return 1;
    }
    int has_bogus = zmq_has("noexistent-mech");
    if (has_bogus != 0) {
        fprintf(stderr, "expected bogus=0 got=%d\n", has_bogus);
        return 2;
    }
    puts("ok zmq_has curve=1");
    return 0;
}
C

gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs libzmq)
"$tmpdir/t" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'ok zmq_has curve=1'
