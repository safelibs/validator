#!/usr/bin/env bash
# @testcase: usage-gio-r10-info-standard-is-backup
# @title: gio info flags tilde-suffixed files via standard::is-backup TRUE
# @description: Creates a file ending with "~" (the Emacs/glib backup convention that GFileInfo's standard::is-backup detector recognises) and verifies "gio info -a standard::is-backup" reports TRUE while a normal file reports FALSE. (.bak suffix is not surfaced as is-backup; the documented marker is the trailing tilde.)
# @timeout: 60
# @tags: usage, gio, info
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'plain\n' >"$tmpdir/normal.txt"
printf 'backup\n' >"$tmpdir/data~"
gio info -a standard::is-backup "$tmpdir/normal.txt" >"$tmpdir/normal.out"
gio info -a standard::is-backup "$tmpdir/data~" >"$tmpdir/bak.out"
grep -E 'standard::is-backup:[[:space:]]*FALSE' "$tmpdir/normal.out" >/dev/null
grep -E 'standard::is-backup:[[:space:]]*TRUE' "$tmpdir/bak.out" >/dev/null
