from __future__ import annotations

import argparse
import copy
import html
import json
import os
import sys
from pathlib import Path
from typing import Any

if __package__ in {None, ""}:
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from tools import ValidatorError, ensure_parent, write_json
from tools import proof as proof_tools


MODE_ORDER = {"original": 0, "safe": 1}
REQUIRED_RESULT_FIELDS = {
    "library",
    "mode",
    "status",
    "started_at",
    "finished_at",
    "duration_seconds",
    "log_path",
    "cast_path",
}


def result_sort_key(result: dict[str, Any]) -> tuple[str, int, str]:
    return (
        str(result["library"]),
        MODE_ORDER.get(str(result["mode"]), 99),
        str(result["mode"]),
    )


def relative_href(*, output_root: Path, artifacts_root: Path, relative_path: str | None) -> str | None:
    if relative_path is None:
        return None
    target = artifacts_root / relative_path
    return os.path.relpath(target, start=output_root)


def validate_artifact_relative_path(
    relative_path: str | None,
    *,
    field_name: str,
    artifacts_root: Path,
    source_path: Path,
) -> Path | None:
    return proof_tools.validate_artifact_relative_path(
        relative_path,
        field_name=field_name,
        artifacts_root=artifacts_root,
        source_path=source_path,
    )


def load_results(results_root: Path, *, artifacts_root: Path) -> list[dict[str, Any]]:
    if not results_root.is_dir():
        raise ValidatorError(f"results root does not exist: {results_root}")

    results: list[dict[str, Any]] = []
    for path in sorted(results_root.glob("*/*.json")):
        payload = json.loads(path.read_text())
        if not REQUIRED_RESULT_FIELDS <= set(payload):
            raise ValidatorError(f"result schema mismatch in {path}: {sorted(payload)}")
        validate_artifact_relative_path(
            payload["log_path"],
            field_name="log_path",
            artifacts_root=artifacts_root,
            source_path=path,
        )
        validate_artifact_relative_path(
            payload["cast_path"],
            field_name="cast_path",
            artifacts_root=artifacts_root,
            source_path=path,
        )
        results.append(payload)

    if not results:
        raise ValidatorError(f"no result JSON files found under {results_root}")
    return sorted(results, key=result_sort_key)


def load_proof(proof_path: Path, *, artifacts_root: Path, output_root: Path) -> dict[str, Any]:
    proof_path_resolved = proof_path.resolve(strict=False)
    artifacts_root_resolved = artifacts_root.resolve(strict=False)
    try:
        proof_path_resolved.relative_to(artifacts_root_resolved)
    except ValueError as exc:
        raise ValidatorError(f"proof path must resolve inside artifact root: {proof_path}") from exc

    try:
        proof_data = json.loads(proof_path.read_text())
    except FileNotFoundError as exc:
        raise ValidatorError(f"missing proof manifest: {proof_path}") from exc
    except json.JSONDecodeError as exc:
        raise ValidatorError(f"invalid proof manifest JSON at {proof_path}: {exc}") from exc
    if not isinstance(proof_data, dict):
        raise ValidatorError(f"proof manifest must be a JSON object: {proof_path}")

    site_proof = copy.deepcopy(proof_data)
    libraries = site_proof.get("libraries")
    if not isinstance(libraries, list):
        raise ValidatorError(f"proof manifest must contain libraries list: {proof_path}")
    for library_entry in libraries:
        if not isinstance(library_entry, dict):
            raise ValidatorError(f"proof library entries must be objects: {proof_path}")
        for mode in ("original", "safe"):
            mode_entry = library_entry.get(mode)
            if not isinstance(mode_entry, dict):
                continue
            cast_path = mode_entry.get("cast_path")
            if cast_path is None:
                continue
            cast_target = validate_artifact_relative_path(
                cast_path,
                field_name="cast_path",
                artifacts_root=artifacts_root,
                source_path=proof_path,
            )
            assert cast_target is not None
            if not cast_target.is_file():
                raise ValidatorError(f"proof cast_path does not exist: {cast_path}")
            mode_entry["cast_href"] = relative_href(
                output_root=output_root,
                artifacts_root=artifacts_root,
                relative_path=cast_path,
            )
    return site_proof


def _filter_results_for_proof(
    results: list[dict[str, Any]],
    *,
    proof_data: dict[str, Any],
) -> list[dict[str, Any]]:
    included = proof_data.get("included_libraries")
    if not isinstance(included, list) or not all(isinstance(item, str) for item in included):
        raise ValidatorError("proof included_libraries must be a list of strings")
    included_set = set(included)
    if len(included_set) != len(included):
        raise ValidatorError("proof included_libraries must not contain duplicates")

    filtered: list[dict[str, Any]] = [
        result
        for result in results
        if str(result.get("library")) in included_set
    ]
    row_keys = [(str(result.get("library")), str(result.get("mode"))) for result in filtered]
    expected_keys = {(library, mode) for library in included for mode in MODE_ORDER}
    actual_keys = set(row_keys)
    duplicates = sorted(key for key in actual_keys if row_keys.count(key) > 1)
    if duplicates:
        raise ValidatorError(f"duplicate result rows for proof libraries: {duplicates}")
    if actual_keys != expected_keys:
        raise ValidatorError(
            f"result rows must cover exactly both modes for proof libraries: "
            f"expected {sorted(expected_keys)}, found {sorted(actual_keys)}"
        )
    return sorted(filtered, key=result_sort_key)


def render_index(site_rows: list[dict[str, Any]], proof_data: dict[str, Any] | None = None) -> str:
    total = len(site_rows)
    passed = sum(1 for row in site_rows if row["status"] == "passed")
    failed = total - passed
    rows = []
    for row in site_rows:
        cast_link = (
            f'<a href="{html.escape(str(row["cast_href"]))}">cast</a>'
            if row["cast_href"] is not None
            else '<span class="muted">n/a</span>'
        )
        rows.append(
            "\n".join(
                [
                    f'      <tr data-library="{html.escape(row["library"])}" data-mode="{html.escape(row["mode"])}">',
                    f'        <td>{html.escape(row["library"])}</td>',
                    f'        <td>{html.escape(row["mode"])}</td>',
                    f'        <td class="status status-{html.escape(row["status"])}">{html.escape(row["status"])}</td>',
                    f'        <td><a href="{html.escape(str(row["log_href"]))}">log</a></td>',
                    f"        <td>{cast_link}</td>",
                    "      </tr>",
                ]
            )
        )

    proof_section: list[str] = []
    if proof_data is not None:
        proof_rows: list[str] = []
        for library_entry in proof_data.get("libraries", []):
            library = str(library_entry["library"])
            original = library_entry["original"]
            safe = library_entry["safe"]
            safe_cast_href = safe.get("cast_href")
            safe_cast_link = (
                f'<a href="{html.escape(str(safe_cast_href))}">{html.escape(str(safe["cast_path"]))}</a>'
                if safe_cast_href is not None
                else '<span class="muted">n/a</span>'
            )
            proof_rows.append(
                "\n".join(
                    [
                        f'      <tr data-proof-library="{html.escape(library)}">',
                        f"        <td>{html.escape(library)}</td>",
                        f'        <td class="status status-{html.escape(str(original["status"]))}">{html.escape(str(original["status"]))}</td>',
                        f'        <td class="status status-{html.escape(str(safe["status"]))}">{html.escape(str(safe["status"]))}</td>',
                        f"        <td>{safe_cast_link}</td>",
                        f'        <td>{html.escape(str(safe["cast_events"]))}</td>',
                        f'        <td>{html.escape(str(original["summary"]["expected_dependents"]))}</td>',
                        f'        <td>{html.escape(str(safe["summary"]["expected_dependents"]))}</td>',
                        f'        <td>{html.escape(str(original["summary"]["report_format"]))}</td>',
                        f'        <td>{html.escape(str(safe["summary"]["report_format"]))}</td>',
                        "      </tr>",
                    ]
                )
            )
        exclusion_rows: list[str] = []
        for exclusion in proof_data.get("excluded_libraries", []):
            library = str(exclusion["library"])
            note = str(exclusion["note"])
            exclusion_rows.append(
                f'      <p data-proof-excluded-library="{html.escape(library)}">'
                f'<strong>{html.escape(library)}</strong>: {html.escape(note)}</p>'
            )
        proof_section = [
            '      <section class="proof">',
            "        <h2>Asciinema proof</h2>",
            "        <table>",
            "          <thead>",
            "            <tr>",
            "              <th>Library</th>",
            "              <th>Original</th>",
            "              <th>Safe</th>",
            "              <th>Safe cast</th>",
            "              <th>Events</th>",
            "              <th>Original workloads</th>",
            "              <th>Safe workloads</th>",
            "              <th>Original format</th>",
            "              <th>Safe format</th>",
            "            </tr>",
            "          </thead>",
            "          <tbody>",
            *proof_rows,
            "          </tbody>",
            "        </table>",
            *exclusion_rows,
            "      </section>",
        ]

    return "\n".join(
        [
            "<!doctype html>",
            '<html lang="en">',
            "  <head>",
            '    <meta charset="utf-8">',
            '    <meta name="viewport" content="width=device-width, initial-scale=1">',
            "    <title>SafeLibs validator matrix</title>",
            "    <style>",
            "      :root { color-scheme: light; font-family: 'IBM Plex Sans', 'Segoe UI', sans-serif; }",
            "      body { margin: 0; background: linear-gradient(180deg, #f4efe4 0%, #fffdf8 100%); color: #16221f; }",
            "      main { max-width: 960px; margin: 0 auto; padding: 48px 24px 72px; }",
            "      h1 { margin: 0 0 12px; font-size: clamp(2.25rem, 5vw, 3.5rem); }",
            "      h2 { margin: 36px 0 16px; font-size: 1.7rem; }",
            "      p { line-height: 1.6; }",
            "      .hero { margin-bottom: 32px; padding: 28px; border-radius: 24px; background: rgba(255, 255, 255, 0.85); box-shadow: 0 18px 48px rgba(29, 52, 44, 0.08); }",
            "      .summary { display: flex; gap: 16px; flex-wrap: wrap; margin-top: 20px; }",
            "      .summary-card { min-width: 140px; padding: 14px 18px; border-radius: 18px; background: #e3ece7; }",
            "      .summary-card strong { display: block; font-size: 1.8rem; }",
            "      table { width: 100%; border-collapse: collapse; background: rgba(255, 255, 255, 0.92); border-radius: 22px; overflow: hidden; box-shadow: 0 18px 48px rgba(29, 52, 44, 0.08); }",
            "      .proof table { font-size: 0.95rem; }",
            "      th, td { padding: 16px 18px; text-align: left; border-bottom: 1px solid rgba(22, 34, 31, 0.08); }",
            "      th { font-size: 0.85rem; text-transform: uppercase; letter-spacing: 0.08em; color: #56655f; background: rgba(227, 236, 231, 0.85); }",
            "      tr:last-child td { border-bottom: 0; }",
            "      .status { font-weight: 700; text-transform: uppercase; letter-spacing: 0.04em; }",
            "      .status-passed { color: #17643f; }",
            "      .status-failed { color: #9d2e2e; }",
            "      .muted { color: #7b8982; }",
            "      a { color: #0a5c7a; text-decoration-thickness: 0.08em; }",
            "      @media (max-width: 720px) {",
            "        main { padding: 28px 16px 48px; }",
            "        th, td { padding: 12px; }",
            "        table { display: block; overflow-x: auto; }",
            "      }",
            "    </style>",
            "  </head>",
            "  <body>",
            "    <main>",
            '      <section class="hero">',
            "        <p>Static report rendered directly from validator result JSON.</p>",
            "        <h1>SafeLibs validator matrix</h1>",
            "        <p>Each row links to the captured run log and, when available, the safe-mode terminal cast.</p>",
            '        <div class="summary">',
            f'          <div class="summary-card"><strong>{total}</strong><span>Runs</span></div>',
            f'          <div class="summary-card"><strong>{passed}</strong><span>Passed</span></div>',
            f'          <div class="summary-card"><strong>{failed}</strong><span>Failed</span></div>',
            "        </div>",
            "      </section>",
            "      <table>",
            "        <thead>",
            "          <tr>",
            "            <th>Library</th>",
            "            <th>Mode</th>",
            "            <th>Status</th>",
            "            <th>Log</th>",
            "            <th>Cast</th>",
            "          </tr>",
            "        </thead>",
            "        <tbody>",
            *rows,
            "        </tbody>",
            "      </table>",
            *proof_section,
            "    </main>",
            "  </body>",
            "</html>",
            "",
        ]
    )


def build_site_rows(results: list[dict[str, Any]], *, output_root: Path, artifacts_root: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for result in results:
        log_path = str(result["log_path"])
        cast_path = result["cast_path"]
        rows.append(
            {
                "library": str(result["library"]),
                "mode": str(result["mode"]),
                "status": str(result["status"]),
                "log_path": log_path,
                "cast_path": cast_path,
                "log_href": relative_href(
                    output_root=output_root,
                    artifacts_root=artifacts_root,
                    relative_path=log_path,
                ),
                "cast_href": relative_href(
                    output_root=output_root,
                    artifacts_root=artifacts_root,
                    relative_path=cast_path,
                ),
            }
        )
    return rows


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    parser.add_argument("--results-root", required=True, type=Path)
    parser.add_argument("--artifacts-root", required=True, type=Path)
    parser.add_argument("--output-root", required=True, type=Path)
    parser.add_argument("--proof-path", type=Path)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    results = load_results(args.results_root, artifacts_root=args.artifacts_root)
    proof_data: dict[str, Any] | None = None
    if args.proof_path is not None:
        proof_data = load_proof(
            args.proof_path,
            artifacts_root=args.artifacts_root,
            output_root=args.output_root,
        )
        results = _filter_results_for_proof(results, proof_data=proof_data)
    site_rows = build_site_rows(results, output_root=args.output_root, artifacts_root=args.artifacts_root)

    args.output_root.mkdir(parents=True, exist_ok=True)
    site_data: dict[str, Any] = {"results": site_rows}
    if proof_data is not None:
        site_data["proof"] = proof_data
    write_json(args.output_root / "site-data.json", site_data)
    ensure_parent(args.output_root / "index.html")
    (args.output_root / "index.html").write_text(render_index(site_rows, proof_data), encoding="utf-8")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ValidatorError as exc:
        print(str(exc), file=sys.stderr)
        raise SystemExit(1)
