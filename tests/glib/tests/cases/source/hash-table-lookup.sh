#!/usr/bin/env bash
# @testcase: hash-table-lookup
# @title: GLib hash table lookup
# @description: Inserts and reads values through the GHashTable API.
# @timeout: 120
# @tags: api, collection

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="hash-table-lookup"
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
