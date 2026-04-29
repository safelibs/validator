#!/usr/bin/env bash
# @testcase: archive-read-api-smoke
# @title: archive read API smoke
# @description: Compiles and runs a libarchive archive_read API listing program.
# @timeout: 120
# @tags: api, compile

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in"; printf 'api\n' >"$tmpdir/in/payload.txt"; bsdtar -cf "$tmpdir/a.tar" -C "$tmpdir/in" .
cat >"$tmpdir/t.c" <<'C'
#include <archive.h>
#include <archive_entry.h>
#include <stdio.h>
int main(int c,char**v){struct archive*a=archive_read_new();struct archive_entry*e;int n=0;archive_read_support_filter_all(a);archive_read_support_format_tar(a);if(archive_read_open_filename(a,v[1],10240)!=ARCHIVE_OK)return 1;while(archive_read_next_header(a,&e)==ARCHIVE_OK){puts(archive_entry_pathname(e));archive_read_data_skip(a);n++;}archive_read_free(a);return n?0:2;}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" -larchive; "$tmpdir/t" "$tmpdir/a.tar"
