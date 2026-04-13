#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
BASELINE="$ROOT/safe/benchmarks/original-baseline.json"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --baseline)
      BASELINE="$2"
      shift 2
      ;;
    *)
      break
      ;;
  esac
done

ORIGINAL_ROOT="${1:?usage: verify-performance.sh [--baseline path] <original-root> <stage-root>}"
STAGE="${2:?usage: verify-performance.sh [--baseline path] <original-root> <stage-root>}"

python3 - "$ROOT" "$BASELINE" "$ORIGINAL_ROOT" "$STAGE" <<'PY'
import json
import os
import subprocess
import sys
from pathlib import Path

root = Path(sys.argv[1]).resolve()
baseline_path = Path(sys.argv[2]).resolve()
original_root = Path(sys.argv[3]).resolve()
stage_root = Path(sys.argv[4]).resolve()
triplet = subprocess.check_output(["gcc", "-print-multiarch"], text=True).strip()
stage_libdir = stage_root / "usr" / "lib" / triplet
stage_bindir = stage_root / "usr" / "bin"
release_bindir = root / "safe" / "target" / "release"
helper_root = root / "safe" / "target" / "upstream-bin"
oracle_record = root / "safe" / "abi" / "baseline" / "original-oracles.txt"
oracles = oracle_record.read_text(encoding="utf-8")

required_oracles = ["original/dba100000.xml", "original/testSAX"]
for oracle in required_oracles:
    if oracle not in oracles:
        raise SystemExit(
            f"refusing to collect or refresh the original baseline because {oracle!r} "
            "is not recorded in safe/abi/baseline/original-oracles.txt"
        )

for path in (
    original_root / ".libs" / "xmllint",
    original_root / "testSAX",
    original_root / "dba100000.xml",
    stage_bindir / "xmllint",
    release_bindir / "xmllint",
    release_bindir / "xmlcatalog",
):
    if not path.exists():
        raise SystemExit(f"missing performance prerequisite: {path}")

env_base = os.environ.copy()
env_base.pop("XML_CATALOG_FILES", None)
env_base.pop("SGML_CATALOG_FILES", None)

subprocess.run([str(root / "safe" / "tests" / "upstream" / "build_helpers.sh")], check=True)

for helper in (helper_root / "testSAX",):
    if not helper.exists():
        raise SystemExit(f"missing rebuilt safe helper: {helper}")

workloads = {
    "xmllint_stream_file": {
        "kind": "stream",
        "argv": ["--stream", "--timing", "dba100000.xml"],
        "cwd": original_root,
    },
    "xmllint_stream_memory": {
        "kind": "stream",
        "argv": ["--stream", "--timing", "--memory", "dba100000.xml"],
        "cwd": original_root,
    },
    "xmllint_repeat_dom": {
        "kind": "dom",
        "argv": ["--noout", "--timing", "--repeat", "./test/valid/REC-xml-19980210.xml"],
        "cwd": original_root,
    },
    "xmllint_repeat_valid": {
        "kind": "dom",
        "argv": ["--noout", "--timing", "--valid", "--repeat", "./test/valid/REC-xml-19980210.xml"],
        "cwd": original_root,
    },
    "testsax_repeat": {
        "kind": "stream",
        "argv": ["--timing", "--repeat", "dba100000.xml"],
        "cwd": original_root,
    },
}


def run_timed(label: str, binary: Path, argv: list[str], cwd: Path, libdir: Path | None) -> dict[str, object]:
    metrics_path = root / "safe" / "target" / "benchmarks" / f"{label}.time"
    metrics_path.parent.mkdir(parents=True, exist_ok=True)
    env = env_base.copy()
    if libdir is not None:
        env["LD_LIBRARY_PATH"] = f"{libdir}:{env.get('LD_LIBRARY_PATH', '')}".rstrip(":")
    cmd = ["/usr/bin/time", "-f", "%e %M", "-o", str(metrics_path), str(binary), *argv]
    completed = subprocess.run(
        cmd,
        cwd=cwd,
        env=env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if completed.returncode != 0:
        raise SystemExit(
            f"{label} failed with exit {completed.returncode}\n"
            f"stdout:\n{completed.stdout}\n"
            f"stderr:\n{completed.stderr}"
        )

    metric_text = metrics_path.read_text(encoding="utf-8").strip().split()
    if len(metric_text) != 2:
        raise SystemExit(f"unable to parse timing metrics for {label}: {metrics_path.read_text()!r}")

    elapsed_sec = float(metric_text[0])
    max_rss_kib = int(metric_text[1])
    metrics_path.unlink(missing_ok=True)
    return {
        "elapsed_sec": elapsed_sec,
        "max_rss_kib": max_rss_kib,
        "stdout": completed.stdout,
        "stderr": completed.stderr,
    }


def collect_original_baseline() -> dict[str, object]:
    results: dict[str, object] = {
        "meta": {
            "generator": "safe/scripts/verify-performance.sh",
            "original_root": "original",
            "original_xmllint": "original/.libs/xmllint",
            "original_testSAX": "original/testSAX",
            "oracle_record": "safe/abi/baseline/original-oracles.txt",
            "thresholds": {
                "stream_time_ratio": 2.0,
                "dom_time_ratio": 2.5,
                "stream_rss_ratio": 1.5,
                "stream_rss_abs_kib": 16384,
            },
        },
        "workloads": {},
    }
    for name, spec in workloads.items():
        binary = original_root / "testSAX" if name.startswith("testsax") else original_root / ".libs" / "xmllint"
        results["workloads"][name] = run_timed(
            f"original-{name}",
            binary,
            spec["argv"],
            spec["cwd"],
            original_root / ".libs",
        )
    return results


if not baseline_path.is_file():
    raise SystemExit(
        f"missing recorded performance baseline: {baseline_path}\n"
        "phase 09 consumes the preexisting baseline in place and must not regenerate it"
    )

baseline = json.loads(baseline_path.read_text(encoding="utf-8"))

safe_results = {}
for name, spec in workloads.items():
    binary = helper_root / "testSAX" if name.startswith("testsax") else stage_bindir / "xmllint"
    safe_results[name] = run_timed(
        f"safe-{name}",
        binary,
        spec["argv"],
        spec["cwd"],
        stage_libdir,
    )

thresholds = baseline.get("meta", {}).get("thresholds", {})
stream_time_ratio = float(thresholds.get("stream_time_ratio", 2.0))
dom_time_ratio = float(thresholds.get("dom_time_ratio", 2.5))
stream_rss_ratio = float(thresholds.get("stream_rss_ratio", 1.5))
stream_rss_abs_kib = int(thresholds.get("stream_rss_abs_kib", 16384))

failures: list[str] = []
summary: list[str] = []
for name, spec in workloads.items():
    base = baseline["workloads"][name]
    safe = safe_results[name]
    ratio = safe["elapsed_sec"] / max(base["elapsed_sec"], 0.001)
    rss_ratio = safe["max_rss_kib"] / max(base["max_rss_kib"], 1)
    summary.append(
        f"{name}: elapsed {safe['elapsed_sec']:.3f}s vs {base['elapsed_sec']:.3f}s "
        f"({ratio:.2f}x), max RSS {safe['max_rss_kib']} KiB vs {base['max_rss_kib']} KiB "
        f"({rss_ratio:.2f}x)"
    )
    limit = stream_time_ratio if spec["kind"] == "stream" else dom_time_ratio
    if ratio > limit:
        failures.append(f"{name} exceeded its performance envelope: {ratio:.2f}x slower (limit {limit:.2f}x)")
    if spec["kind"] == "stream":
        rss_growth = safe["max_rss_kib"] - base["max_rss_kib"]
        if rss_growth > stream_rss_abs_kib and rss_ratio > stream_rss_ratio:
            failures.append(
                f"{name} streaming memory grew materially: +{rss_growth} KiB "
                f"({rss_ratio:.2f}x, limit {stream_rss_ratio:.2f}x and +{stream_rss_abs_kib} KiB)"
            )

print("performance summary:")
for line in summary:
    print(f"  {line}")

if failures:
    raise SystemExit("performance verification failed:\n" + "\n".join(failures))
PY
