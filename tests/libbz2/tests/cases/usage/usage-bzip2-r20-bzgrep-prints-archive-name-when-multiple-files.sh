#!/usr/bin/env bash
# @testcase: usage-bzip2-r20-bzgrep-prints-archive-name-when-multiple-files
# @title: bzgrep prefixes every match line with the archive filename when given multiple archives
# @description: Compresses two archives each containing a single line that matches the pattern "needle", runs bzgrep 'needle' against both archive names, and asserts every output line begins with one of the two archive filenames followed by a colon, exercising the default filename-prefix behavior in multi-file mode distinct from prior --no-filename (-h) tests.
# @timeout: 30
# @tags: usage, bzgrep, multi-file, prefix, r20
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cd "$tmpdir"

printf 'needle in first\nother text\n' >first.txt
printf 'another needle\nirrelevant\n' >second.txt
bzip2 first.txt
bzip2 second.txt

got=$(bzgrep 'needle' first.txt.bz2 second.txt.bz2)
n=$(printf '%s\n' "$got" | wc -l)
[[ "$n" -eq 2 ]] || {
    printf 'expected 2 lines, got %s:\n%s\n' "$n" "$got" >&2
    exit 1
}

while IFS= read -r line; do
    case "$line" in
        "first.txt.bz2:"*|"second.txt.bz2:"*) ;;
        *)
            printf 'unexpected unprefixed line: %s\n' "$line" >&2
            exit 1
            ;;
    esac
done <<<"$got"
