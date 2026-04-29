#!/usr/bin/env bash
# @testcase: streaming-c-api-smoke
# @title: libzstd streaming C API smoke
# @description: Compiles and runs a Zstandard streaming compression smoke program.
# @timeout: 120
# @tags: api, compile

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <zstd.h>
#include <stdio.h>
#include <string.h>
int main(void){const char in[]="zstd streaming api payload";char c[256],out[256];ZSTD_CCtx*cc=ZSTD_createCCtx();ZSTD_inBuffer ib={in,strlen(in),0};ZSTD_outBuffer ob={c,sizeof c,0};size_t r=ZSTD_compressStream2(cc,&ob,&ib,ZSTD_e_end);if(ZSTD_isError(r))return 1;ZSTD_freeCCtx(cc);ZSTD_DCtx*dc=ZSTD_createDCtx();ZSTD_inBuffer di={c,ob.pos,0};ZSTD_outBuffer oo={out,sizeof out,0};r=ZSTD_decompressStream(dc,&oo,&di);if(ZSTD_isError(r))return 2;out[oo.pos]=0;printf("decoded=%s\n",out);ZSTD_freeDCtx(dc);return strcmp(out,in);}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" -lzstd; "$tmpdir/t"
