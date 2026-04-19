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


REQUIRED_RESULT_FIELDS = {
    "schema_version",
    "library",
    "mode",
    "testcase_id",
    "title",
    "description",
    "kind",
    "client_application",
    "tags",
    "requires",
    "status",
    "started_at",
    "finished_at",
    "duration_seconds",
    "result_path",
    "log_path",
    "cast_path",
    "exit_code",
    "command",
    "apt_packages",
    "override_debs_installed",
}


def result_sort_key(result: dict[str, Any]) -> tuple[str, str]:
    return (str(result["library"]), str(result["testcase_id"]))


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


def _load_json_object(path: Path) -> dict[str, Any]:
    try:
        payload = json.loads(path.read_text())
    except FileNotFoundError as exc:
        raise ValidatorError(f"missing JSON file: {path}") from exc
    except json.JSONDecodeError as exc:
        raise ValidatorError(f"invalid JSON at {path}: {exc}") from exc
    if not isinstance(payload, dict):
        raise ValidatorError(f"JSON payload must be an object: {path}")
    return payload


def load_results(results_root: Path, *, artifacts_root: Path) -> list[dict[str, Any]]:
    if not results_root.is_dir():
        raise ValidatorError(f"results root does not exist: {results_root}")

    results: list[dict[str, Any]] = []
    for path in sorted(results_root.glob("*/*.json")):
        if path.name == "summary.json":
            continue
        payload = _load_json_object(path)
        if not REQUIRED_RESULT_FIELDS <= set(payload):
            raise ValidatorError(f"result schema mismatch in {path}: {sorted(payload)}")
        if payload.get("schema_version") != 2:
            raise ValidatorError(f"result schema_version must be 2 in {path}")
        if payload.get("mode") != "original":
            raise ValidatorError(f"result mode must be original in {path}")
        validate_artifact_relative_path(
            payload["result_path"],
            field_name="result_path",
            artifacts_root=artifacts_root,
            source_path=path,
        )
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

    proof_data = _load_json_object(proof_path)
    if proof_data.get("proof_version") != 2:
        raise ValidatorError(f"proof_version must be 2 in {proof_path}")
    if proof_data.get("mode") != "original":
        raise ValidatorError(f"proof mode must be original in {proof_path}")

    site_proof = copy.deepcopy(proof_data)
    libraries = site_proof.get("libraries")
    if not isinstance(libraries, list):
        raise ValidatorError(f"proof manifest must contain libraries list: {proof_path}")
    for library_entry in libraries:
        if not isinstance(library_entry, dict):
            raise ValidatorError(f"proof library entries must be objects: {proof_path}")
        cases = library_entry.get("cases")
        if not isinstance(cases, list):
            raise ValidatorError(f"proof library entries must contain cases lists: {proof_path}")
        for case_entry in cases:
            if not isinstance(case_entry, dict):
                raise ValidatorError(f"proof case entries must be objects: {proof_path}")
            cast_path = case_entry.get("cast_path")
            if cast_path is None:
                case_entry["cast_href"] = None
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
            case_entry["cast_href"] = relative_href(
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

    filtered = [result for result in results if str(result.get("library")) in included_set]
    row_keys = [(str(result.get("library")), str(result.get("testcase_id"))) for result in filtered]
    expected_keys = {
        (str(library_entry["library"]), str(case_entry["testcase_id"]))
        for library_entry in proof_data.get("libraries", [])
        if isinstance(library_entry, dict)
        for case_entry in library_entry.get("cases", [])
        if isinstance(case_entry, dict)
    }
    actual_keys = set(row_keys)
    duplicates = sorted(key for key in actual_keys if row_keys.count(key) > 1)
    if duplicates:
        raise ValidatorError(f"duplicate result rows for proof cases: {duplicates}")
    if actual_keys != expected_keys:
        raise ValidatorError(
            f"result rows must cover exactly proof cases: "
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
                    f'      <tr data-library="{html.escape(row["library"])}" data-testcase="{html.escape(row["testcase_id"])}">',
                    f'        <td>{html.escape(row["library"])}</td>',
                    f'        <td>{html.escape(row["testcase_id"])}</td>',
                    f'        <td>{html.escape(row["kind"])}</td>',
                    f'        <td class="status status-{html.escape(row["status"])}">{html.escape(row["status"])}</td>',
                    f'        <td><a href="{html.escape(str(row["log_href"]))}">log</a></td>',
                    f"        <td>{cast_link}</td>",
                    "      </tr>",
                ]
            )
        )

    proof_section: list[str] = []
    if proof_data is not None:
        totals = proof_data.get("totals", {})
        proof_summary = [
            '        <div class="summary proof-summary">',
            f'          <div class="summary-card" data-proof-total="included_libraries"><strong>{html.escape(str(totals.get("included_libraries", "")))}</strong><span>Included libraries</span></div>',
            f'          <div class="summary-card" data-proof-total="excluded_libraries"><strong>{html.escape(str(totals.get("excluded_libraries", "")))}</strong><span>Excluded libraries</span></div>',
            f'          <div class="summary-card" data-proof-total="cases"><strong>{html.escape(str(totals.get("cases", "")))}</strong><span>Cases</span></div>',
            f'          <div class="summary-card" data-proof-total="source_cases"><strong>{html.escape(str(totals.get("source_cases", "")))}</strong><span>Source cases</span></div>',
            f'          <div class="summary-card" data-proof-total="usage_cases"><strong>{html.escape(str(totals.get("usage_cases", "")))}</strong><span>Usage cases</span></div>',
            f'          <div class="summary-card" data-proof-total="passed"><strong>{html.escape(str(totals.get("passed", "")))}</strong><span>Passed</span></div>',
            f'          <div class="summary-card" data-proof-total="failed"><strong>{html.escape(str(totals.get("failed", "")))}</strong><span>Failed</span></div>',
            f'          <div class="summary-card" data-proof-total="casts"><strong>{html.escape(str(totals.get("casts", "")))}</strong><span>Casts</span></div>',
            "        </div>",
        ]
        proof_rows: list[str] = []
        for library_entry in proof_data.get("libraries", []):
            library = str(library_entry["library"])
            for case_entry in library_entry.get("cases", []):
                case_id = str(case_entry["testcase_id"])
                cast_href = case_entry.get("cast_href")
                cast_path = case_entry.get("cast_path")
                cast_link = (
                    f'<a href="{html.escape(str(cast_href))}">{html.escape(str(cast_path))}</a>'
                    if cast_href is not None
                    else '<span class="muted">n/a</span>'
                )
                proof_rows.append(
                    "\n".join(
                        [
                            f'      <tr data-proof-library="{html.escape(library)}" data-proof-testcase="{html.escape(case_id)}">',
                            f"        <td>{html.escape(library)}</td>",
                            f"        <td>{html.escape(case_id)}</td>",
                            f'        <td>{html.escape(str(case_entry["kind"]))}</td>',
                            f'        <td class="status status-{html.escape(str(case_entry["status"]))}">{html.escape(str(case_entry["status"]))}</td>',
                            f"        <td>{cast_link}</td>",
                            f'        <td>{html.escape(str(case_entry.get("cast_events", "")))}</td>',
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
            *proof_summary,
            "        <table>",
            "          <thead>",
            "            <tr>",
            "              <th>Library</th>",
            "              <th>Testcase</th>",
            "              <th>Kind</th>",
            "              <th>Status</th>",
            "              <th>Cast</th>",
            "              <th>Events</th>",
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
            "    <title>Validator original testcase matrix</title>",
            "    <style>",
            "      :root { color-scheme: light; font-family: 'IBM Plex Sans', 'Segoe UI', sans-serif; }",
            "      body { margin: 0; background: #f7f8f5; color: #16221f; }",
            "      main { max-width: 1040px; margin: 0 auto; padding: 48px 24px 72px; }",
            "      h1 { margin: 0 0 12px; font-size: clamp(2.25rem, 5vw, 3.5rem); }",
            "      h2 { margin: 36px 0 16px; font-size: 1.7rem; }",
            "      p { line-height: 1.6; }",
            "      .hero { margin-bottom: 32px; padding: 28px; background: #ffffff; border: 1px solid rgba(22, 34, 31, 0.1); }",
            "      .summary { display: flex; gap: 16px; flex-wrap: wrap; margin-top: 20px; }",
            "      .summary-card { min-width: 130px; padding: 14px 18px; background: #e8eee9; }",
            "      .summary-card strong { display: block; font-size: 1.8rem; }",
            "      .proof-summary { margin-bottom: 18px; }",
            "      table { width: 100%; border-collapse: collapse; background: #ffffff; border: 1px solid rgba(22, 34, 31, 0.1); }",
            "      .proof table { font-size: 0.95rem; }",
            "      th, td { padding: 14px 16px; text-align: left; border-bottom: 1px solid rgba(22, 34, 31, 0.08); }",
            "      th { font-size: 0.85rem; text-transform: uppercase; color: #56655f; background: #e8eee9; }",
            "      tr:last-child td { border-bottom: 0; }",
            "      .status { font-weight: 700; text-transform: uppercase; }",
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
            "        <h1>Validator original testcase matrix</h1>",
            "        <p>Each row links to the captured testcase run log and terminal cast when present.</p>",
            '        <div class="summary">',
            f'          <div class="summary-card"><strong>{total}</strong><span>Cases</span></div>',
            f'          <div class="summary-card"><strong>{passed}</strong><span>Passed</span></div>',
            f'          <div class="summary-card"><strong>{failed}</strong><span>Failed</span></div>',
            "        </div>",
            "      </section>",
            "      <table>",
            "        <thead>",
            "          <tr>",
            "            <th>Library</th>",
            "            <th>Testcase</th>",
            "            <th>Kind</th>",
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
                "testcase_id": str(result["testcase_id"]),
                "kind": str(result["kind"]),
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
