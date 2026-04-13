#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)"
TRIPLET="$(gcc -print-multiarch)"
STAGE="$ROOT/safe/target/stage"
OUT="$ROOT/safe/target/upstream-bin"

mkdir -p "$OUT"

compile_helper() {
  local source="$1"
  local output="$2"
  cc -DHAVE_CONFIG_H \
    -I"$ROOT/safe/include" \
    -I"$ROOT/original" \
    -I"$STAGE/usr/include/libxml2" \
    "$source" \
    -L"$STAGE/usr/lib/$TRIPLET" \
    -Wl,-rpath,'$ORIGIN/../stage/usr/lib/'"$TRIPLET" \
    -Wl,--enable-new-dtags \
    -lxml2 -lz -llzma -lm -ldl -lpthread \
    -o "$output"
}

compile_fuzz_helper() {
  local output="$1"
  shift
  cc -DHAVE_CONFIG_H \
    -I"$ROOT/safe/include" \
    -I"$ROOT/original" \
    -I"$ROOT/original/fuzz" \
    -I"$STAGE/usr/include/libxml2" \
    "$@" \
    -L"$STAGE/usr/lib/$TRIPLET" \
    -Wl,-rpath,'$ORIGIN/../stage/usr/lib/'"$TRIPLET" \
    -Wl,--enable-new-dtags \
    -lxml2 -lz -llzma -lm -ldl -lpthread \
    -o "$output"
}

compile_helper "$ROOT/original/runtest.c" "$OUT/runtest"
compile_helper "$ROOT/original/testrecurse.c" "$OUT/testrecurse"
compile_helper "$ROOT/original/testapi.c" "$OUT/testapi"
compile_helper "$ROOT/original/testchar.c" "$OUT/testchar"
compile_helper "$ROOT/original/testdict.c" "$OUT/testdict"
compile_helper "$ROOT/original/runxmlconf.c" "$OUT/runxmlconf"
compile_helper "$ROOT/original/testThreads.c" "$OUT/testThreads"
compile_helper "$ROOT/original/testURI.c" "$OUT/testURI"
compile_helper "$ROOT/original/testlimits.c" "$OUT/testlimits"
compile_helper "$ROOT/original/testReader.c" "$OUT/testReader"
compile_helper "$ROOT/original/testSAX.c" "$OUT/testSAX"
compile_helper "$ROOT/original/testHTML.c" "$OUT/testHTML"
compile_helper "$ROOT/original/testXPath.c" "$OUT/testXPath"
compile_helper "$ROOT/original/testRegexp.c" "$OUT/testRegexp"
compile_helper "$ROOT/original/testAutomata.c" "$OUT/testAutomata"
compile_helper "$ROOT/original/testC14N.c" "$OUT/testC14N"
compile_helper "$ROOT/original/testModule.c" "$OUT/testModule"
compile_helper "$ROOT/original/testSchemas.c" "$OUT/testSchemas"
compile_helper "$ROOT/original/testRelax.c" "$OUT/testRelax"
compile_helper "$ROOT/original/example/gjobread.c" "$OUT/gjobread"
compile_fuzz_helper "$OUT/genSeed" "$ROOT/original/fuzz/genSeed.c" "$ROOT/original/fuzz/fuzz.c"
compile_fuzz_helper "$OUT/testFuzzer" "$ROOT/original/fuzz/testFuzzer.c" "$ROOT/original/fuzz/fuzz.c"

cc -shared -fPIC -DHAVE_CONFIG_H \
  -I"$ROOT/safe/include" \
  -I"$ROOT/original" \
  -I"$STAGE/usr/include/libxml2" \
  "$ROOT/original/testdso.c" \
  -L"$STAGE/usr/lib/$TRIPLET" \
  -Wl,-rpath,'$ORIGIN/../stage/usr/lib/'"$TRIPLET" \
  -Wl,--enable-new-dtags \
  -lxml2 -lz -llzma -lm -ldl -lpthread \
  -o "$OUT/testdso.so"
