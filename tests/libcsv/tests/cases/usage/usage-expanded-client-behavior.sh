#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

workload=${1:?missing readstat workload}
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

if workload == "dta-mixed-case-header":
    write_csv("CodeValue\nalpha\n")
    out = roundtrip("dta", [{"type": "STRING", "name": "CodeValue"}])
    assert out.splitlines()[0] == '"CodeValue"'
    assert '"alpha"' in out
    print(out.strip())
elif workload == "sav-mixed-case-header":
    write_csv("CodeValue\nalpha\n")
    out = roundtrip("sav", [{"type": "STRING", "name": "CodeValue"}])
    assert out.splitlines()[0] == '"CodeValue"'
    assert '"alpha"' in out
    print(out.strip())
elif workload == "dta-numeric-string":
    write_csv("code\n3.50\n")
    out = roundtrip("dta", [{"type": "STRING", "name": "code"}])
    assert '"3.50"' in out
    print(out.strip())
elif workload == "sav-numeric-string":
    write_csv("code\n3.50\n")
    out = roundtrip("sav", [{"type": "STRING", "name": "code"}])
    assert '"3.50"' in out
    print(out.strip())
elif workload == "dta-two-row-strings":
    write_csv("name\nalpha\nbeta\n")
    out = roundtrip("dta", [{"type": "STRING", "name": "name"}])
    assert '"alpha"' in out
    assert '"beta"' in out
    assert out.index('"alpha"') < out.index('"beta"')
    print(out.strip())
elif workload == "sav-two-row-strings":
    write_csv("name\nalpha\nbeta\n")
    out = roundtrip("sav", [{"type": "STRING", "name": "name"}])
    assert '"alpha"' in out
    assert '"beta"' in out
    assert out.index('"alpha"') < out.index('"beta"')
    print(out.strip())
elif workload == "dta-multiline-note":
    write_csv('note\n"line one\nline two"\n')
    out = roundtrip("dta", [{"type": "STRING", "name": "note"}])
    assert 'line one' in out
    assert 'line two' in out
    assert out.index('line one') < out.index('line two')
    print(out.strip())
elif workload == "sav-multiline-note":
    write_csv('note\n"line one\nline two"\n')
    out = roundtrip("sav", [{"type": "STRING", "name": "note"}])
    assert 'line one' in out
    assert 'line two' in out
    assert out.index('line one') < out.index('line two')
    print(out.strip())
elif workload == "dta-zero-number":
    write_csv("score\n0\n")
    out = roundtrip("dta", [{"type": "NUMERIC", "name": "score"}])
    assert '0.000000' in out
    print(out.strip())
elif workload == "sav-zero-number":
    write_csv("score\n0\n")
    out = roundtrip("sav", [{"type": "NUMERIC", "name": "score"}])
    assert '0.000000' in out
    print(out.strip())
else:
    raise SystemExit(f"unknown readstat expanded workload: {workload}")
PYCASE
