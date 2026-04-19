#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/t.c" <<'C'
#include <libxml/xmlreader.h>
#include <stdio.h>
#include <string.h>
int main(void){const char x[]="<root><child>text</child></root>";xmlTextReaderPtr r=xmlReaderForMemory(x,strlen(x),NULL,NULL,0);int n=0;while(xmlTextReaderRead(r)==1){if(xmlTextReaderNodeType(r)==XML_READER_TYPE_ELEMENT){printf("element=%s\n",xmlTextReaderConstName(r));n++;}}xmlFreeTextReader(r);xmlCleanupParser();return n==2?0:1;}
C
gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs libxml-2.0); "$tmpdir/t"
