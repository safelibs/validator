#!/usr/bin/env bash
# @testcase: usage-libzmq5-r9-pair-inproc
# @title: ZeroMQ PAIR inproc roundtrip
# @description: Compiles a single-process ZMQ_PAIR client over an inproc:// transport and verifies bidirectional message exchange.
# @timeout: 180
# @tags: usage, zmq, inproc
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
    void *ctx = zmq_ctx_new();
    void *a = zmq_socket(ctx, ZMQ_PAIR);
    void *b = zmq_socket(ctx, ZMQ_PAIR);
    int timeout = 2000;
    zmq_setsockopt(a, ZMQ_RCVTIMEO, &timeout, sizeof(timeout));
    zmq_setsockopt(b, ZMQ_RCVTIMEO, &timeout, sizeof(timeout));
    if (zmq_bind(a, "inproc://r9-pair") != 0) { perror("bind"); return 1; }
    if (zmq_connect(b, "inproc://r9-pair") != 0) { perror("connect"); return 1; }

    const char *msg1 = "from-a";
    const char *msg2 = "from-b";
    if (zmq_send(a, msg1, strlen(msg1), 0) != (int)strlen(msg1)) return 1;

    char buf[64] = {0};
    int n = zmq_recv(b, buf, sizeof(buf) - 1, 0);
    if (n != (int)strlen(msg1) || memcmp(buf, msg1, n) != 0) return 2;

    if (zmq_send(b, msg2, strlen(msg2), 0) != (int)strlen(msg2)) return 1;
    char buf2[64] = {0};
    int n2 = zmq_recv(a, buf2, sizeof(buf2) - 1, 0);
    if (n2 != (int)strlen(msg2) || memcmp(buf2, msg2, n2) != 0) return 3;

    zmq_close(a); zmq_close(b); zmq_ctx_term(ctx);
    printf("pair ok\n");
    return 0;
}
C

gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs libzmq)
"$tmpdir/t"
