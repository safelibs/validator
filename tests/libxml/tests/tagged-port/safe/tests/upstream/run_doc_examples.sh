#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)"
TRIPLET="$(gcc -print-multiarch)"
STAGE="$ROOT/safe/target/stage"
BUILD_DIR="$ROOT/safe/target/upstream-bin/doc-examples"
WORK_DIR="$ROOT/safe/target/upstream-bin/doc-examples-work"
SRC_DIR="$ROOT/original/doc/examples"

mkdir -p "$BUILD_DIR" "$WORK_DIR"
ln -sf "$SRC_DIR/test1.xml" "$WORK_DIR/test1.xml"
ln -sf "$SRC_DIR/test2.xml" "$WORK_DIR/test2.xml"
ln -sf "$SRC_DIR/test3.xml" "$WORK_DIR/test3.xml"

compile_example() {
  local source="$1"
  local output="$2"
  cc -DHAVE_CONFIG_H \
    -I"$ROOT/safe/include" \
    -I"$ROOT/original" \
    -I"$STAGE/usr/include/libxml2" \
    "$source" \
    -L"$STAGE/usr/lib/$TRIPLET" \
    -Wl,-rpath,'$ORIGIN/../../stage/usr/lib/'"$TRIPLET" \
    -Wl,--enable-new-dtags \
    -lxml2 -lz -llzma -lm -ldl -lpthread \
    -o "$output"
}

for name in io1 io2 parse1 parse2 parse3 parse4 reader1 reader2 reader3 reader4 testWriter tree1 tree2 xpath1 xpath2; do
  compile_example "$SRC_DIR/$name.c" "$BUILD_DIR/$name"
done

cd "$WORK_DIR"

"$BUILD_DIR/io1" >"$WORK_DIR/io1.tmp"
diff -u "$SRC_DIR/io1.res" "$WORK_DIR/io1.tmp"
"$BUILD_DIR/io2" >"$WORK_DIR/io2.tmp"
diff -u "$SRC_DIR/io2.res" "$WORK_DIR/io2.tmp"
"$BUILD_DIR/parse1" "$WORK_DIR/test1.xml"
"$BUILD_DIR/parse2" "$WORK_DIR/test2.xml"
"$BUILD_DIR/parse3"
"$BUILD_DIR/parse4" "$WORK_DIR/test3.xml"
"$BUILD_DIR/reader1" "$WORK_DIR/test2.xml" >"$WORK_DIR/reader1.tmp"
diff -u "$SRC_DIR/reader1.res" "$WORK_DIR/reader1.tmp"
"$BUILD_DIR/reader2" "$WORK_DIR/test2.xml" >"$WORK_DIR/reader2.tmp"
diff -u "$SRC_DIR/reader1.res" "$WORK_DIR/reader2.tmp"
"$BUILD_DIR/reader3" >"$WORK_DIR/reader3.tmp"
diff -u "$SRC_DIR/reader3.res" "$WORK_DIR/reader3.tmp"
"$BUILD_DIR/reader4" test1.xml test2.xml test3.xml >"$WORK_DIR/reader4.tmp"
diff -u "$SRC_DIR/reader4.res" "$WORK_DIR/reader4.tmp"
"$BUILD_DIR/testWriter"
for index in 1 2 3 4; do
  diff -u "$SRC_DIR/writer.xml" "$WORK_DIR/writer${index}.tmp"
done
"$BUILD_DIR/tree1" "$WORK_DIR/test2.xml" >"$WORK_DIR/tree1.tmp"
diff -u "$SRC_DIR/tree1.res" "$WORK_DIR/tree1.tmp"
"$BUILD_DIR/tree2" >"$WORK_DIR/tree2.tmp"
diff -u "$SRC_DIR/tree2.res" "$WORK_DIR/tree2.tmp"
"$BUILD_DIR/xpath1" "$WORK_DIR/test3.xml" "//child2" >"$WORK_DIR/xpath1.tmp"
diff -u "$SRC_DIR/xpath1.res" "$WORK_DIR/xpath1.tmp"
"$BUILD_DIR/xpath2" "$WORK_DIR/test3.xml" "//discarded" "discarded" >"$WORK_DIR/xpath2.tmp"
diff -u "$SRC_DIR/xpath2.res" "$WORK_DIR/xpath2.tmp"
