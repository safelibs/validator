#!/usr/bin/env bash
# @testcase: usage-python3-configparser-roundtrip
# @title: python3 configparser INI roundtrip
# @description: Writes and reads an INI file with python3 configparser and verifies the section values survive the roundtrip.
# @timeout: 180
# @tags: usage, python, runtime
# @client: python3-minimal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-configparser-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/config.ini" "$tmpdir/out" <<'PY'
import configparser
import sys

ini_path, out_path = sys.argv[1], sys.argv[2]

writer = configparser.ConfigParser()
writer["server"] = {"host": "localhost", "port": "8080"}
writer["client"] = {"timeout": "30"}
with open(ini_path, "w") as fh:
    writer.write(fh)

reader = configparser.ConfigParser()
reader.read(ini_path)
with open(out_path, "w") as fh:
    fh.write("host=" + reader["server"]["host"] + "\n")
    fh.write("port=" + reader["server"]["port"] + "\n")
    fh.write("timeout=" + reader["client"]["timeout"] + "\n")
PY

validator_assert_contains "$tmpdir/out" 'host=localhost'
validator_assert_contains "$tmpdir/out" 'port=8080'
validator_assert_contains "$tmpdir/out" 'timeout=30'
