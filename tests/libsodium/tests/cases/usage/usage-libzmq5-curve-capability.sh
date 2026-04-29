#!/usr/bin/env bash
# @testcase: usage-libzmq5-curve-capability
# @title: ZeroMQ reports CURVE capability
# @description: Compiles a ZeroMQ capability check that queries libsodium-backed CURVE support.
# @timeout: 180
# @tags: usage, compile
# @client: libzmq5

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT


    cat >"$tmpdir/t.c" <<'C'
#include <zmq.h>
#include <stdio.h>
int main(void){printf("curve=%d\n", zmq_has("curve")); return 0;}
C
    gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs libzmq)
    "$tmpdir/t"
