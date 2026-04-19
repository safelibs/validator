#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <uv.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
int main(int c,char**v){uv_fs_t r;int fd=uv_fs_open(uv_default_loop(),&r,v[1],O_CREAT|O_TRUNC|O_RDWR,0600,NULL);uv_fs_req_cleanup(&r);uv_buf_t b=uv_buf_init("uv fs payload",13);uv_fs_write(uv_default_loop(),&r,fd,&b,1,0,NULL);uv_fs_req_cleanup(&r);char out[32]={0};uv_buf_t rb=uv_buf_init(out,sizeof out);uv_fs_read(uv_default_loop(),&r,fd,&rb,1,0,NULL);uv_fs_req_cleanup(&r);uv_fs_close(uv_default_loop(),&r,fd,NULL);uv_fs_req_cleanup(&r);printf("read=%s\n",out);return strcmp(out,"uv fs payload");}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" -luv; "$tmpdir/t" "$tmpdir/file"
