#!/usr/bin/env bash
# @testcase: main-loop-timeout
# @title: GLib main loop timeout
# @description: Runs a GMainLoop until a timeout source updates state and exits.
# @timeout: 120
# @tags: api, mainloop

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="main-loop-timeout"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

compile_and_run() {
  local needle=$1
  shift
  cat >"$tmpdir/t.c"
  gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs "$@")
  "$tmpdir/t" >"$tmpdir/out"
  validator_assert_contains "$tmpdir/out" "$needle"
}

compile_and_run 'value=42' glib-2.0 <<'C'
#include <glib.h>
#include <stdio.h>
static GMainLoop *loop;
static int value = 0;
static gboolean tick(gpointer data) {
    (void)data;
    value = 42;
    g_main_loop_quit(loop);
    return G_SOURCE_REMOVE;
}
int main(void) {
    loop = g_main_loop_new(NULL, FALSE);
    g_timeout_add(10, tick, NULL);
    g_main_loop_run(loop);
    g_main_loop_unref(loop);
    printf("value=%d\n", value);
    return value == 42 ? 0 : 1;
}
C
