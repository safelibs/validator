#!/usr/bin/env bash
# @testcase: usage-libzmq5-r14-req-rep-inproc-roundtrip
# @title: ZeroMQ REQ/REP inproc request/reply roundtrip
# @description: Compiles a single-process C program that binds a ZMQ_REP socket and connects a ZMQ_REQ socket over inproc://, sends "ping" from the requester, asserts the replier observes the request bytes, replies "pong", and asserts the requester recovers the reply bytes — exercising libzmq's libsodium-linked runtime.
# @timeout: 180
# @tags: usage, zmq, req, rep, inproc
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
    void *rep = zmq_socket(ctx, ZMQ_REP);
    void *req = zmq_socket(ctx, ZMQ_REQ);

    int timeout = 2000;
    zmq_setsockopt(rep, ZMQ_RCVTIMEO, &timeout, sizeof(timeout));
    zmq_setsockopt(req, ZMQ_RCVTIMEO, &timeout, sizeof(timeout));

    if (zmq_bind(rep, "inproc://r14-reqrep") != 0) { perror("bind"); return 1; }
    if (zmq_connect(req, "inproc://r14-reqrep") != 0) { perror("connect"); return 2; }

    const char *q = "ping";
    if (zmq_send(req, q, strlen(q), 0) != (int)strlen(q)) return 3;

    char rbuf[64] = {0};
    int rn = zmq_recv(rep, rbuf, sizeof(rbuf) - 1, 0);
    if (rn != (int)strlen(q) || memcmp(rbuf, q, rn) != 0) {
        fprintf(stderr, "request mismatch n=%d\n", rn);
        return 4;
    }

    const char *a = "pong";
    if (zmq_send(rep, a, strlen(a), 0) != (int)strlen(a)) return 5;

    char qbuf[64] = {0};
    int qn = zmq_recv(req, qbuf, sizeof(qbuf) - 1, 0);
    if (qn != (int)strlen(a) || memcmp(qbuf, a, qn) != 0) {
        fprintf(stderr, "reply mismatch n=%d\n", qn);
        return 6;
    }

    zmq_close(req);
    zmq_close(rep);
    zmq_ctx_term(ctx);
    puts("ok");
    return 0;
}
C

gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs libzmq)
"$tmpdir/t"
