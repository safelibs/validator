#!/usr/bin/env bash
# @testcase: key-file-roundtrip
# @title: GLib key file round trip
# @description: Serializes and reloads a GKeyFile with string and integer values.
# @timeout: 120
# @tags: api, keyfile

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="key-file-roundtrip"
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

compile_and_run 'message=hello count=3' glib-2.0 <<'C'
#include <glib.h>
#include <stdio.h>
int main(void) {
    GKeyFile *key = g_key_file_new();
    g_key_file_set_string(key, "demo", "message", "hello");
    g_key_file_set_integer(key, "demo", "count", 3);
    gsize len = 0;
    gchar *data = g_key_file_to_data(key, &len, NULL);
    GKeyFile *copy = g_key_file_new();
    g_key_file_load_from_data(copy, data, len, G_KEY_FILE_NONE, NULL);
    gchar *message = g_key_file_get_string(copy, "demo", "message", NULL);
    gint count = g_key_file_get_integer(copy, "demo", "count", NULL);
    printf("message=%s count=%d\n", message, count);
    g_free(message);
    g_free(data);
    g_key_file_unref(copy);
    g_key_file_unref(key);
    return count == 3 ? 0 : 1;
}
C
