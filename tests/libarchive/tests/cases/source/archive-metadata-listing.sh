#!/usr/bin/env bash
# @testcase: archive-metadata-listing
# @title: Archive metadata listing behavior
# @description: Lists archive metadata including modes and symbolic link entries.
# @timeout: 120
# @tags: cli, metadata

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/in"; printf 'target\n' >"$tmpdir/in/target.txt"; ln -s target.txt "$tmpdir/in/link.txt"; bsdtar -cf "$tmpdir/meta.tar" -C "$tmpdir/in" .; bsdtar -tvf "$tmpdir/meta.tar" | LC_ALL=C sort | tee "$tmpdir/list"; grep target.txt "$tmpdir/list"; grep link.txt "$tmpdir/list"
