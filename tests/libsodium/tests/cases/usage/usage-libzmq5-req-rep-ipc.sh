#!/usr/bin/env bash
# @testcase: usage-libzmq5-req-rep-ipc
# @title: ZeroMQ REQ/REP ipc:// transport request/reply roundtrip
# @description: Compiles a ZeroMQ C client that opens a single-process REQ/REP pair over an ipc:// endpoint inside a tmpdir, sends a request from REQ, receives it on REP, sends a reply back, receives it on REQ, and asserts both directions transmit the expected payload bytes exactly. REQ/REP enforces strict alternation, so the test also asserts that the REP-side echo matches the original request bytes after a full round trip. Exercises the libsodium-linked ZeroMQ runtime on the no-encryption ipc transport.
# @timeout: 180
# @tags: usage, zmq, ipc, reqrep
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
    const char *request  = "validator-zmq-req";
    const char *reply    = "validator-zmq-rep";
    const size_t qlen    = strlen(request);
    const size_t plen    = strlen(reply);

    void *ctx = zmq_ctx_new();
    if (!ctx) { perror("zmq_ctx_new"); return 1; }

    void *rep = zmq_socket(ctx, ZMQ_REP);
    void *req = zmq_socket(ctx, ZMQ_REQ);
    if (!rep || !req) { fprintf(stderr, "socket create failed\n"); return 1; }

    int timeout = 2000; /* ms */
    if (zmq_setsockopt(req, ZMQ_RCVTIMEO, &timeout, sizeof(timeout)) != 0) return 1;
    if (zmq_setsockopt(rep, ZMQ_RCVTIMEO, &timeout, sizeof(timeout)) != 0) return 1;
    if (zmq_setsockopt(req, ZMQ_SNDTIMEO, &timeout, sizeof(timeout)) != 0) return 1;
    if (zmq_setsockopt(rep, ZMQ_SNDTIMEO, &timeout, sizeof(timeout)) != 0) return 1;

    if (zmq_bind(rep, endpoint) != 0)    { perror("bind");    return 1; }
    if (zmq_connect(req, endpoint) != 0) { perror("connect"); return 1; }

    /* REQ sends request. */
    if ((size_t)zmq_send(req, request, qlen, 0) != qlen) { perror("req send"); return 1; }

    /* REP receives, validates, sends reply. */
    char rbuf[256] = {0};
    int rn = zmq_recv(rep, rbuf, sizeof(rbuf) - 1, 0);
    if (rn < 0) { perror("rep recv"); return 1; }
    if ((size_t)rn != qlen || memcmp(rbuf, request, qlen) != 0) {
        fprintf(stderr, "REP got unexpected request: '%.*s'\n", rn, rbuf);
        return 3;
    }
    if ((size_t)zmq_send(rep, reply, plen, 0) != plen) { perror("rep send"); return 1; }

    /* REQ receives reply. */
    char qbuf[256] = {0};
    int qn = zmq_recv(req, qbuf, sizeof(qbuf) - 1, 0);
    if (qn < 0) { perror("req recv"); return 1; }
    if ((size_t)qn != plen || memcmp(qbuf, reply, plen) != 0) {
        fprintf(stderr, "REQ got unexpected reply: '%.*s'\n", qn, qbuf);
        return 4;
    }

    zmq_close(req);
    zmq_close(rep);
    zmq_ctx_term(ctx);
    printf("ok %d %d\n", rn, qn);
    return 0;
}
C

gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs libzmq)
endpoint="ipc://$tmpdir/zmq.sock"
"$tmpdir/t" "$endpoint"
