#!/usr/bin/env bash
# @testcase: gio-file-roundtrip
# @title: GIO file round trip
# @description: Writes and reads a file through GFile utility APIs.
# @timeout: 120
# @tags: api, gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="gio-file-roundtrip"
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

compile_and_run 'gio payload' gio-2.0 <<'C'
#include <gio/gio.h>
#include <stdio.h>
int main(void) {
    GFile *file = g_file_new_for_path("/tmp/glib-gio-roundtrip.txt");
    const char *payload = "gio payload\n";
    g_file_replace_contents(file, payload, -1, NULL, FALSE, G_FILE_CREATE_NONE, NULL, NULL, NULL);
    gchar *contents = NULL;
    gsize len = 0;
    g_file_load_contents(file, NULL, &contents, &len, NULL, NULL);
    printf("%s", contents);
    g_free(contents);
    g_object_unref(file);
    return 0;
}
C
