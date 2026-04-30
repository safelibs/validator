#!/usr/bin/env bash
# @testcase: usage-libzmq5-pub-sub-ipc
# @title: ZeroMQ PUB/SUB ipc:// transport with topic filter
# @description: Compiles a ZeroMQ C client that opens a single-process PUB/SUB pair over an ipc:// endpoint inside a tmpdir, subscribes to a fixed topic prefix, retries the publish on the slow-joiner window with a small ZMQ_RCVTIMEO, and asserts the SUB socket receives exactly the published topic+payload bytes. Exercises the libsodium-linked ZeroMQ runtime on the no-encryption ipc transport with the SUB-side subscription filter.
# @timeout: 180
# @tags: usage, zmq, ipc, pubsub
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

int main(int argc, char **argv) {
    if (argc < 2) { fprintf(stderr, "missing endpoint\n"); return 2; }
    const char *endpoint = argv[1];
    const char *topic    = "validator.topic ";
    const char *body     = "validator-zmq-pub-sub";
    char message[256];
    int mlen = snprintf(message, sizeof(message), "%s%s", topic, body);
    if (mlen <= 0 || (size_t)mlen >= sizeof(message)) return 1;

    void *ctx = zmq_ctx_new();
    if (!ctx) return 1;

    void *sub = zmq_socket(ctx, ZMQ_SUB);
    void *pub = zmq_socket(ctx, ZMQ_PUB);
    if (!sub || !pub) return 1;

    int timeout = 250; /* ms */
    if (zmq_setsockopt(sub, ZMQ_RCVTIMEO, &timeout, sizeof(timeout)) != 0) return 1;
    /* Subscribe to "validator." prefix. */
    if (zmq_setsockopt(sub, ZMQ_SUBSCRIBE, "validator.", 10) != 0) return 1;

    if (zmq_bind(sub, endpoint) != 0)    { perror("bind");    return 1; }
    if (zmq_connect(pub, endpoint) != 0) { perror("connect"); return 1; }

    /* PUB/SUB has a slow-joiner window; retry until the SUB sees one message. */
    char buf[256];
    int got = -1;
    for (int attempt = 0; attempt < 40; ++attempt) {
        if (zmq_send(pub, message, mlen, 0) != mlen) { perror("send"); return 1; }
        int n = zmq_recv(sub, buf, sizeof(buf) - 1, 0);
        if (n >= 0) { got = n; buf[n] = '\0'; break; }
        if (zmq_errno() != EAGAIN) { perror("recv"); return 1; }
    }
    if (got < 0) {
        fprintf(stderr, "SUB never received a message\n");
        return 3;
    }
    if (got != mlen || memcmp(buf, message, mlen) != 0) {
        fprintf(stderr, "payload mismatch: got '%.*s'\n", got, buf);
        return 4;
    }

    zmq_close(pub);
    zmq_close(sub);
    zmq_ctx_term(ctx);
    printf("ok %d\n", got);
    return 0;
}
C

gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs libzmq)
endpoint="ipc://$tmpdir/zmq.sock"
"$tmpdir/t" "$endpoint"
