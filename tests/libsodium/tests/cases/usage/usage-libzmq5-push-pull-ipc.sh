#!/usr/bin/env bash
# @testcase: usage-libzmq5-push-pull-ipc
# @title: ZeroMQ PUSH/PULL ipc:// transport roundtrip
# @description: Compiles a ZeroMQ C client that opens a single-process PUSH/PULL pair over an ipc:// endpoint inside a tmpdir, sends a fixed payload from PUSH and receives it on PULL, then asserts the received bytes match the original exactly. Exercises the ZeroMQ runtime that links against libsodium (used for CURVE on other transports) on the no-encryption ipc transport.
# @timeout: 180
# @tags: usage, zmq, ipc
# @client: libzmq5

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <zmq.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

int main(int argc, char **argv) {
    if (argc < 2) { fprintf(stderr, "missing endpoint\n"); return 2; }
    const char *endpoint = argv[1];
    const char *payload  = "validator-zmq-push-pull";
    const size_t plen    = strlen(payload);

    void *ctx = zmq_ctx_new();
    if (!ctx) { perror("zmq_ctx_new"); return 1; }

    void *pull = zmq_socket(ctx, ZMQ_PULL);
    void *push = zmq_socket(ctx, ZMQ_PUSH);
    if (!pull || !push) { fprintf(stderr, "socket create failed\n"); return 1; }

    if (zmq_bind(pull, endpoint) != 0)    { perror("bind");    return 1; }
    if (zmq_connect(push, endpoint) != 0) { perror("connect"); return 1; }

    if ((size_t)zmq_send(push, payload, plen, 0) != plen) {
        perror("send"); return 1;
    }

    char buf[256] = {0};
    int n = zmq_recv(pull, buf, sizeof(buf) - 1, 0);
    if (n < 0) { perror("recv"); return 1; }
    if ((size_t)n != plen || memcmp(buf, payload, plen) != 0) {
        fprintf(stderr, "payload mismatch: got '%.*s'\n", n, buf);
        return 3;
    }

    zmq_close(push);
    zmq_close(pull);
    zmq_ctx_term(ctx);
    printf("ok %d\n", n);
    return 0;
}
C

gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs libzmq)
endpoint="ipc://$tmpdir/zmq.sock"
"$tmpdir/t" "$endpoint"
