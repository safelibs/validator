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

def run(*args):
    subprocess.run(args, check=True, cwd=tmpdir)

def capture(*args):
    return subprocess.check_output(args, cwd=tmpdir, text=True)

def write_csv(text):
    (tmpdir / "in.csv").write_text(text)

def write_metadata(variables):
    (tmpdir / "meta.json").write_text(json.dumps({"type": "SPSS", "variables": variables}))

def roundtrip(kind):
    write_target = tmpdir / f"out.{kind}"
    run("readstat", str(tmpdir / "in.csv"), str(tmpdir / "meta.json"), str(write_target))
    return capture("readstat", str(write_target), "-")

if workload == "dta-negative-number":
    write_csv("name,delta\nalpha,-3.5\n")
    write_metadata([{"type": "STRING", "name": "name"}, {"type": "NUMERIC", "name": "delta"}])
    out = roundtrip("dta")
    assert '"alpha",-3.500000' in out
    print(out.strip())
elif workload == "sav-negative-number":
    write_csv("name,delta\nalpha,-3.5\n")
    write_metadata([{"type": "STRING", "name": "name"}, {"type": "NUMERIC", "name": "delta"}])
    out = roundtrip("sav")
    assert '"alpha",-3.500000' in out
    print(out.strip())
elif workload == "dta-leading-zero-string":
    write_csv("code\n0012\n")
    write_metadata([{"type": "STRING", "name": "code"}])
    out = roundtrip("dta")
    assert '"0012"' in out
    print(out.strip())
elif workload == "sav-leading-zero-string":
    write_csv("code\n0012\n")
    write_metadata([{"type": "STRING", "name": "code"}])
    out = roundtrip("sav")
    assert '"0012"' in out
    print(out.strip())
elif workload == "dta-two-row-strings":
    write_csv("name\nalpha\nbeta\n")
    write_metadata([{"type": "STRING", "name": "name"}])
    out = roundtrip("dta")
    assert '"alpha"' in out
    assert '"beta"' in out
    assert out.index('"alpha"') < out.index('"beta"')
    print(out.strip())
elif workload == "sav-two-row-strings":
    write_csv("name\nalpha\nbeta\n")
    write_metadata([{"type": "STRING", "name": "name"}])
    out = roundtrip("sav")
    assert '"alpha"' in out
    assert '"beta"' in out
    assert out.index('"alpha"') < out.index('"beta"')
    print(out.strip())
elif workload == "dta-long-string":
    write_csv("name\nvalidator-long-string-value\n")
    write_metadata([{"type": "STRING", "name": "name"}])
    out = roundtrip("dta")
    assert 'validator-long-string-value' in out
    print(out.strip())
elif workload == "sav-long-string":
    write_csv("name\nvalidator-long-string-value\n")
    write_metadata([{"type": "STRING", "name": "name"}])
    out = roundtrip("sav")
    assert 'validator-long-string-value' in out
    print(out.strip())
elif workload == "dta-zero-number":
    write_csv("score\n0\n")
    write_metadata([{"type": "NUMERIC", "name": "score"}])
    out = roundtrip("dta")
    assert '0.000000' in out
    print(out.strip())
elif workload == "sav-zero-number":
    write_csv("score\n0\n")
    write_metadata([{"type": "NUMERIC", "name": "score"}])
    out = roundtrip("sav")
    assert '0.000000' in out
    print(out.strip())
else:
    raise SystemExit(f"unknown readstat expanded workload: {workload}")
PYCASE
