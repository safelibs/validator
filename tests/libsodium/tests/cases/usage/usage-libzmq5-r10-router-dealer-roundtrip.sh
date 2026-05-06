#!/usr/bin/env bash
# @testcase: usage-libzmq5-r10-router-dealer-roundtrip
# @title: ZeroMQ ROUTER/DEALER inproc multipart roundtrip
# @description: Compiles a single-process ZeroMQ test that binds a ROUTER socket and connects a DEALER socket over inproc://, sends a request frame from the DEALER, reads the routing identity plus payload on the ROUTER, replies back through the same identity, and asserts the DEALER receives the reply payload.
# @timeout: 180
# @tags: usage, zmq, router, dealer, inproc
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
    void *router = zmq_socket(ctx, ZMQ_ROUTER);
    void *dealer = zmq_socket(ctx, ZMQ_DEALER);

    int timeout = 2000;
    zmq_setsockopt(router, ZMQ_RCVTIMEO, &timeout, sizeof(timeout));
    zmq_setsockopt(dealer, ZMQ_RCVTIMEO, &timeout, sizeof(timeout));

    if (zmq_bind(router, "inproc://r10-router") != 0) { perror("bind"); return 1; }
    if (zmq_connect(dealer, "inproc://r10-router") != 0) { perror("connect"); return 1; }

    const char *req = "hello-router";
    if (zmq_send(dealer, req, strlen(req), 0) != (int)strlen(req)) return 2;

    /* ROUTER receives an identity frame followed by the payload frame. */
    zmq_msg_t id_msg, payload_msg;
    zmq_msg_init(&id_msg);
    if (zmq_msg_recv(&id_msg, router, 0) < 0) { perror("recv id"); return 3; }
    if (!zmq_msg_more(&id_msg)) { fprintf(stderr, "no payload follow-on\n"); return 4; }

    zmq_msg_init(&payload_msg);
    if (zmq_msg_recv(&payload_msg, router, 0) < 0) { perror("recv payload"); return 5; }
    if (zmq_msg_size(&payload_msg) != strlen(req) ||
        memcmp(zmq_msg_data(&payload_msg), req, strlen(req)) != 0) {
        fprintf(stderr, "request payload mismatch\n");
        return 6;
    }

    /* Reply: send identity frame + reply payload back through ROUTER. */
    if (zmq_send(router, zmq_msg_data(&id_msg), zmq_msg_size(&id_msg), ZMQ_SNDMORE) < 0) return 7;
    const char *rep = "hello-dealer";
    if (zmq_send(router, rep, strlen(rep), 0) != (int)strlen(rep)) return 8;

    char buf[64] = {0};
    int n = zmq_recv(dealer, buf, sizeof(buf) - 1, 0);
    if (n != (int)strlen(rep) || memcmp(buf, rep, n) != 0) {
        fprintf(stderr, "reply payload mismatch (got %d bytes)\n", n);
        return 9;
    }

    zmq_msg_close(&id_msg);
    zmq_msg_close(&payload_msg);
    zmq_close(router); zmq_close(dealer); zmq_ctx_term(ctx);
    printf("router-dealer ok\n");
    return 0;
}
C

gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs libzmq)
"$tmpdir/t"
