from __future__ import annotations

import argparse
import html
import json
import os
import sys
from pathlib import Path
from typing import Any

if __package__ in {None, ""}:
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from tools import ValidatorError, ensure_parent, write_json


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
    if relative_path is None:
        return None
    if not isinstance(relative_path, str) or not relative_path:
        raise ValidatorError(f"{field_name} must be a non-empty artifact-root-relative path in {source_path}")
    if "\\" in relative_path:
        raise ValidatorError(f"{field_name} must use artifact-root-relative paths in {source_path}")

    relative = Path(relative_path)
    if relative.is_absolute() or any(part in {"", ".", ".."} for part in relative.parts):
        raise ValidatorError(f"{field_name} must be artifact-root-relative in {source_path}")

    target = (artifacts_root / relative).resolve(strict=False)
    try:
        target.relative_to(artifacts_root.resolve(strict=False))
    except ValueError as exc:
        raise ValidatorError(f"{field_name} must stay within the artifact root in {source_path}") from exc
    return target


def load_results(results_root: Path) -> list[dict[str, Any]]:
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
            artifacts_root=results_root.parent,
            source_path=path,
        )
        validate_artifact_relative_path(
            payload["cast_path"],
            field_name="cast_path",
            artifacts_root=results_root.parent,
            source_path=path,
        )
        results.append(payload)

    if not results:
        raise ValidatorError(f"no result JSON files found under {results_root}")
    return sorted(results, key=result_sort_key)


def render_index(site_rows: list[dict[str, Any]]) -> str:
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
            "      p { line-height: 1.6; }",
            "      .hero { margin-bottom: 32px; padding: 28px; border-radius: 24px; background: rgba(255, 255, 255, 0.85); box-shadow: 0 18px 48px rgba(29, 52, 44, 0.08); }",
            "      .summary { display: flex; gap: 16px; flex-wrap: wrap; margin-top: 20px; }",
            "      .summary-card { min-width: 140px; padding: 14px 18px; border-radius: 18px; background: #e3ece7; }",
            "      .summary-card strong { display: block; font-size: 1.8rem; }",
            "      table { width: 100%; border-collapse: collapse; background: rgba(255, 255, 255, 0.92); border-radius: 22px; overflow: hidden; box-shadow: 0 18px 48px rgba(29, 52, 44, 0.08); }",
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
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    results = load_results(args.results_root)
    site_rows = build_site_rows(results, output_root=args.output_root, artifacts_root=args.artifacts_root)

    args.output_root.mkdir(parents=True, exist_ok=True)
    write_json(args.output_root / "site-data.json", {"results": site_rows})
    ensure_parent(args.output_root / "index.html")
    (args.output_root / "index.html").write_text(render_index(site_rows), encoding="utf-8")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ValidatorError as exc:
        print(str(exc), file=sys.stderr)
        raise SystemExit(1)
