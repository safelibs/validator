#!/usr/bin/env bash
# @testcase: usage-libzmq5-r11-pub-sub-prefix-filter
# @title: ZeroMQ PUB/SUB inproc subscription filter delivers only matching prefix
# @description: Compiles a single-process ZeroMQ test that binds a PUB socket and subscribes a SUB socket to the prefix "hi" over inproc://, sends two messages "hi-msg" and "skip-msg" from the publisher, and asserts the subscriber receives "hi-msg" while the non-matching "skip-msg" is filtered out.
# @timeout: 180
# @tags: usage, zmq, pubsub, filter
# @client: libzmq5

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <zmq.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

int main(void) {
    void *ctx = zmq_ctx_new();
    void *pub = zmq_socket(ctx, ZMQ_PUB);
    void *sub = zmq_socket(ctx, ZMQ_SUB);

    if (zmq_bind(pub, "inproc://r11-prefix") != 0) { perror("bind"); return 1; }
    if (zmq_setsockopt(sub, ZMQ_SUBSCRIBE, "hi", 2) != 0) { perror("subscribe"); return 2; }
    if (zmq_connect(sub, "inproc://r11-prefix") != 0) { perror("connect"); return 3; }

    int timeout = 1500;
    zmq_setsockopt(sub, ZMQ_RCVTIMEO, &timeout, sizeof(timeout));

    /* First message matches the subscription prefix "hi". */
    if (zmq_send(pub, "hi-msg", 6, 0) != 6) { perror("send hi"); return 4; }
    /* Second message does not match the subscription prefix. */
    if (zmq_send(pub, "skip-msg", 8, 0) != 8) { perror("send skip"); return 5; }

    char buf[64];
    int n = zmq_recv(sub, buf, sizeof(buf), 0);
    if (n != 6 || memcmp(buf, "hi-msg", 6) != 0) {
        fprintf(stderr, "first recv mismatch n=%d\n", n);
        return 6;
    }

    /* No further matching message; the subscriber must time out. */
    int n2 = zmq_recv(sub, buf, sizeof(buf), 0);
    if (n2 != -1) {
        fprintf(stderr, "unexpected second recv n=%d (filter leaked)\n", n2);
        return 7;
    }

    zmq_close(sub);
    zmq_close(pub);
    zmq_ctx_term(ctx);
    puts("ok");
    return 0;
}
C

gcc -O2 -Wall -Werror "$tmpdir/t.c" -lzmq -o "$tmpdir/t"
"$tmpdir/t"
