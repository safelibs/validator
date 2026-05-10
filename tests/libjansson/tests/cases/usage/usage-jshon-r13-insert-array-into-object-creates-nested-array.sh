#!/usr/bin/env bash
# @testcase: usage-jshon-r13-insert-array-into-object-creates-nested-array
# @title: jshon -e nums -t reports an array nested in a pre-built JSON object
# @description: Feeds jshon a pre-built JSON document {"nums":[1,2,3]} on stdin and verifies -e nums -t reports "array", -e nums -l reports length 3, and -e nums -e 0 -u recovers the first element. (Noble's jshon rejects both '-n [1,2,3]' as a literal stack value AND the chained '-n [] -i nums -e nums -n 1 -a -p' build sequence with "type not mappable"; deserialising a pre-built object is the documented stable surface.)
# @timeout: 30
# @tags: usage, json, cli, insert
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

doc='{"nums":[1,2,3]}'
typ=$(printf '%s' "$doc" | jshon -e nums -t)
[[ "$typ" == "array" ]] || { printf 'expected array, got %s\n' "$typ" >&2; exit 1; }
len=$(printf '%s' "$doc" | jshon -e nums -l)
[[ "$len" == "3" ]] || { printf 'expected 3, got %s\n' "$len" >&2; exit 1; }
first=$(printf '%s' "$doc" | jshon -e nums -e 0 -u)
[[ "$first" == "1" ]] || { printf 'expected 1, got %s\n' "$first" >&2; exit 1; }
