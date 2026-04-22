#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
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

case "$case_id" in
  hash-table-lookup)
    compile_and_run 'lookup=42' glib-2.0 <<'C'
#include <glib.h>
#include <stdio.h>
int main(void) {
    GHashTable *table = g_hash_table_new_full(g_str_hash, g_str_equal, g_free, NULL);
    g_hash_table_insert(table, g_strdup("answer"), GINT_TO_POINTER(42));
    printf("lookup=%d\n", GPOINTER_TO_INT(g_hash_table_lookup(table, "answer")));
    g_hash_table_destroy(table);
    return 0;
}
C
    ;;
  main-loop-timeout)
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
    ;;
  variant-tuple-roundtrip)
    compile_and_run 'name=alpha count=7' glib-2.0 <<'C'
#include <glib.h>
#include <stdio.h>
int main(void) {
    GVariant *value = g_variant_new("(si)", "alpha", 7);
    const gchar *name = NULL;
    gint count = 0;
    g_variant_get(value, "(&si)", &name, &count);
    printf("name=%s count=%d\n", name, count);
    return count == 7 ? 0 : 1;
}
C
    ;;
  key-file-roundtrip)
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
    ;;
  gio-file-roundtrip)
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
    ;;
  *)
    printf 'unknown glib source case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
