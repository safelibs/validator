#!/usr/bin/env bash
# @testcase: usage-readstat-sav-mixed-case-header-roundtrip
# @title: readstat SAV mixed-case header
# @description: Converts a mixed-case CSV header to SAV with readstat and verifies the round-tripped header preserves the original column casing.
# @timeout: 180
# @tags: usage, csv, readstat
# @client: readstat

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

workload="usage-readstat-sav-mixed-case-header-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$workload" "$tmpdir"
from pathlib import Path
import json
import subprocess
import sys

workload = sys.argv[1]
tmpdir = Path(sys.argv[2])

if workload.startswith("usage-readstat-"):
    workload = workload[len("usage-readstat-"):]
if workload.endswith("-roundtrip"):
    workload = workload[: -len("-roundtrip")]

def run(*args):
    subprocess.run(args, check=True, cwd=tmpdir)

def capture(*args):
    return subprocess.check_output(args, cwd=tmpdir, text=True)

def write_csv(text):
    (tmpdir / "in.csv").write_text(text)

def metadata_type(kind):
    return "Stata" if kind == "dta" else "SPSS"

def write_metadata(kind, variables):
    (tmpdir / "meta.json").write_text(json.dumps({"type": metadata_type(kind), "variables": variables}))

def roundtrip(kind, variables):
    write_metadata(kind, variables)
    write_target = tmpdir / f"out.{kind}"
    run("readstat", str(tmpdir / "in.csv"), str(tmpdir / "meta.json"), str(write_target))
    return capture("readstat", str(write_target), "-")

raise SystemExit(f"unknown readstat expanded workload: {workload}")
PYCASE
