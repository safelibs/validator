#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <uv.h>
#include <stdio.h>
#include <stdlib.h>

static uv_tcp_t server_handle;
static uv_tcp_t accepted_handle;
static uv_tcp_t client_handle;
static uv_connect_t connect_req;
static int got_data;

static void alloc_cb(uv_handle_t *handle, size_t suggested, uv_buf_t *buf) {
    (void)handle;
    buf->base = malloc(suggested);
    buf->len = suggested;
}

static void read_cb(uv_stream_t *stream, ssize_t nread, const uv_buf_t *buf) {
    if (nread > 0) {
        got_data = 1;
        printf("server-read=%.*s\n", (int)nread, buf->base);
    }
    free(buf->base);
    uv_close((uv_handle_t *)stream, NULL);
    uv_close((uv_handle_t *)&client_handle, NULL);
    uv_close((uv_handle_t *)&server_handle, NULL);
}

static void write_cb(uv_write_t *req, int status) {
    free(req);
    if (status < 0) exit(2);
}

static void connect_cb(uv_connect_t *req, int status) {
    (void)req;
    if (status < 0) exit(3);
    uv_write_t *write_req = malloc(sizeof(*write_req));
    uv_buf_t buf = uv_buf_init("ping", 4);
    uv_write(write_req, (uv_stream_t *)&client_handle, &buf, 1, write_cb);
}

static void connection_cb(uv_stream_t *server, int status) {
    if (status < 0) exit(4);
    uv_tcp_init(uv_default_loop(), &accepted_handle);
    if (uv_accept(server, (uv_stream_t *)&accepted_handle) != 0) exit(5);
    uv_read_start((uv_stream_t *)&accepted_handle, alloc_cb, read_cb);
}

int main(void) {
    struct sockaddr_in addr;
    struct sockaddr_storage bound;
    int len = sizeof(bound);
    uv_ip4_addr("127.0.0.1", 0, &addr);
    uv_tcp_init(uv_default_loop(), &server_handle);
    uv_tcp_bind(&server_handle, (const struct sockaddr *)&addr, 0);
    uv_listen((uv_stream_t *)&server_handle, 1, connection_cb);
    uv_tcp_getsockname(&server_handle, (struct sockaddr *)&bound, &len);
    uv_tcp_init(uv_default_loop(), &client_handle);
    uv_tcp_connect(&connect_req, &client_handle, (const struct sockaddr *)&bound, connect_cb);
    uv_run(uv_default_loop(), UV_RUN_DEFAULT);
    return got_data ? 0 : 6;
}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" -luv; "$tmpdir/t"
