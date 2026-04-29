#!/usr/bin/env bash
# @testcase: streaming-c-api-smoke
# @title: liblzma streaming C API smoke
# @description: Compiles and runs a liblzma streaming encoder smoke program.
# @timeout: 120
# @tags: api, compile

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <lzma.h>
#include <stdio.h>
#include <string.h>
int main(void){const uint8_t in[]="streaming liblzma payload";uint8_t out[512];lzma_stream s=LZMA_STREAM_INIT;if(lzma_easy_encoder(&s,6,LZMA_CHECK_CRC64)!=LZMA_OK)return 1;s.next_in=in;s.avail_in=sizeof(in)-1;s.next_out=out;s.avail_out=sizeof(out);if(lzma_code(&s,LZMA_FINISH)!=LZMA_STREAM_END)return 2;printf("compressed=%zu\n",sizeof(out)-s.avail_out);lzma_end(&s);return 0;}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" -llzma; "$tmpdir/t"
