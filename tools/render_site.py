from __future__ import annotations

import argparse
import copy
import html
import json
import shutil
import sys
from pathlib import Path
from typing import Any

if __package__ in {None, ""}:
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from tools import ValidatorError, ensure_parent, reset_dir, write_json
from tools.inventory import load_manifest
from tools import proof as proof_tools


SITE_DATA_KEYS = ("schema_version", "proof", "testcases")
TESTCASE_ROW_KEYS = (
    "library",
    "testcase_id",
    "mode",
    "title",
    "description",
    "kind",
    "client_application",
    "tags",
    "status",
    "duration_seconds",
    "result_path",
    "log_path",
    "cast_path",
    "log_href",
    "cast_href",
)


def _reject_json_constant(value: str) -> None:
    raise ValueError(f"invalid JSON constant: {value}")


def _load_json_object(path: Path, *, description: str) -> dict[str, Any]:
    try:
        payload = json.loads(path.read_text(), parse_constant=_reject_json_constant)
    except FileNotFoundError as exc:
        raise ValidatorError(f"missing {description}: {path}") from exc
    except ValueError as exc:
        raise ValidatorError(f"invalid {description} JSON at {path}: {exc}") from exc
    if not isinstance(payload, dict):
        raise ValidatorError(f"{description} must be a JSON object: {path}")
    return payload


def _resolve_inside(root: Path, target: Path, *, description: str) -> Path:
    root_resolved = root.resolve(strict=False)
    target_resolved = target.resolve(strict=False)
    try:
        target_resolved.relative_to(root_resolved)
    except ValueError as exc:
        raise ValidatorError(f"{description} must resolve inside {root}: {target}") from exc
    return target_resolved


def _safe_site_component(value: Any, *, field_name: str) -> str:
    if not isinstance(value, str) or not value:
        raise ValidatorError(f"{field_name} must be a non-empty string")
    if value in {".", ".."} or "/" in value or "\\" in value:
        raise ValidatorError(f"{field_name} must be a plain path component: {value!r}")
    return value


def _require_list(value: Any, *, field_name: str) -> list[Any]:
    if not isinstance(value, list):
        raise ValidatorError(f"{field_name} must be a list")
    return value


def _require_dict(value: Any, *, field_name: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise ValidatorError(f"{field_name} must be an object")
    return value


def _evidence_href(*, kind: str, library: str, testcase_id: str, suffix: str) -> str:
    library_component = _safe_site_component(library, field_name="library")
    testcase_component = _safe_site_component(testcase_id, field_name="testcase_id")
    return f"evidence/{kind}/{library_component}/{testcase_component}.{suffix}"


def _page_href(root_href: str | None, *, page_depth: int) -> str | None:
    if root_href is None:
        return None
    return "../" * page_depth + root_href


def _copy_evidence(
    *,
    source: Path,
    output_root: Path,
    href: str,
) -> None:
    target = _resolve_inside(output_root, output_root / href, description="evidence output")
    try:
        source_resolved = source.resolve(strict=True)
    except FileNotFoundError as exc:
        raise ValidatorError(f"missing evidence source: {source}") from exc
    if not source_resolved.is_file():
        raise ValidatorError(f"evidence source must be a file: {source}")
    ensure_parent(target)
    if target.exists() or target.is_symlink():
        target.unlink()
    shutil.copy2(source_resolved, target)


def load_proof(proof_path: Path, *, artifact_root: Path) -> dict[str, Any]:
    artifact_root = artifact_root.resolve(strict=False)
    proof_path_resolved = proof_path.resolve(strict=False)
    try:
        proof_path_resolved.relative_to(artifact_root)
    except ValueError as exc:
        raise ValidatorError(f"proof path must resolve inside artifact root: {proof_path}") from exc
    proof_data = _load_json_object(proof_path, description="proof manifest")
    if proof_data.get("proof_version") != 2:
        raise ValidatorError(f"proof manifest must use proof_version 2: {proof_path}")
    return proof_data


def _proof_libraries(proof_data: dict[str, Any]) -> list[dict[str, Any]]:
    libraries = _require_list(proof_data.get("libraries"), field_name="proof libraries")
    normalized: list[dict[str, Any]] = []
    seen: set[str] = set()
    for entry in libraries:
        library_entry = _require_dict(entry, field_name="proof library")
        library = _safe_site_component(library_entry.get("library"), field_name="library")
        if library in seen:
            raise ValidatorError(f"proof libraries must not contain duplicates: {library}")
        seen.add(library)
        normalized.append(library_entry)
    return normalized


def selected_libraries_from_proof(proof_data: dict[str, Any]) -> list[str]:
    return [str(entry["library"]) for entry in _proof_libraries(proof_data)]


def validate_proof_matches_artifacts(
    proof_data: dict[str, Any],
    *,
    config_path: Path,
    tests_root: Path,
    artifact_root: Path,
) -> None:
    manifest = load_manifest(config_path)
    selected_libraries = selected_libraries_from_proof(proof_data)
    expected_proof = proof_tools.build_proof(
        manifest,
        artifact_root=artifact_root,
        tests_root=tests_root,
        libraries=selected_libraries,
        require_casts=False,
    )
    if expected_proof != proof_data:
        raise ValidatorError("proof manifest does not match rebuilt proof")


def build_site_data(
    proof_data: dict[str, Any],
    *,
    artifact_root: Path,
    output_root: Path,
    copy_evidence: bool = False,
) -> dict[str, Any]:
    if proof_data.get("proof_version") != 2:
        raise ValidatorError("site rendering requires proof_version 2")

    artifact_root = artifact_root.resolve(strict=False)
    output_root = output_root.resolve(strict=False)
    site_proof = copy.deepcopy(proof_data)
    rows: list[dict[str, Any]] = []

    for library_entry in _proof_libraries(site_proof):
        library = _safe_site_component(library_entry.get("library"), field_name="library")
        testcases = _require_list(library_entry.get("testcases"), field_name=f"{library} testcases")
        for raw_case in testcases:
            case = _require_dict(raw_case, field_name=f"{library} testcase")
            testcase_id = _safe_site_component(case.get("testcase_id"), field_name="testcase_id")

            log_path = case.get("log_path")
            if not isinstance(log_path, str) or not log_path:
                raise ValidatorError(f"log_path must be present for {library}/{testcase_id}")
            log_source = proof_tools.validate_artifact_relative_path(
                log_path,
                field_name="log_path",
                artifacts_root=artifact_root,
                source_path=Path(f"proof:{library}/{testcase_id}"),
            )
            assert log_source is not None
            if not log_source.is_file():
                raise ValidatorError(f"proof log_path does not exist: {log_path}")
            log_href = _evidence_href(kind="logs", library=library, testcase_id=testcase_id, suffix="log")
            case["log_href"] = log_href
            if copy_evidence:
                _copy_evidence(source=log_source, output_root=output_root, href=log_href)

            cast_path = case.get("cast_path")
            if cast_path is None:
                cast_href = None
            else:
                if not isinstance(cast_path, str) or not cast_path:
                    raise ValidatorError(f"cast_path must be null or non-empty for {library}/{testcase_id}")
                cast_source = proof_tools.validate_artifact_relative_path(
                    cast_path,
                    field_name="cast_path",
                    artifacts_root=artifact_root,
                    source_path=Path(f"proof:{library}/{testcase_id}"),
                )
                assert cast_source is not None
                if not cast_source.is_file():
                    raise ValidatorError(f"proof cast_path does not exist: {cast_path}")
                cast_href = _evidence_href(kind="casts", library=library, testcase_id=testcase_id, suffix="cast")
                if copy_evidence:
                    _copy_evidence(source=cast_source, output_root=output_root, href=cast_href)
            case["cast_href"] = cast_href

            row = {key: case.get(key) for key in TESTCASE_ROW_KEYS}
            row["library"] = library
            if set(row) != set(TESTCASE_ROW_KEYS):
                raise ValidatorError("internal testcase row shape mismatch")
            rows.append(row)

    return {
        "schema_version": 1,
        "proof": site_proof,
        "testcases": rows,
    }


def _status_label(status: str) -> str:
    return "Passed" if status == "passed" else "Failed"


def _format_duration(value: Any) -> str:
    if isinstance(value, (int, float)):
        return f"{float(value):.2f}s"
    return str(value)


def _summary_cards(site_data: dict[str, Any]) -> str:
    totals = site_data["proof"]["totals"]
    cast_total = int(totals.get("casts", 0))
    case_total = int(totals.get("cases", 0))
    cast_coverage = "0%" if case_total == 0 else f"{round((cast_total / case_total) * 100):d}%"
    cards = [
        ("libraries", "Libraries", totals.get("libraries", 0)),
        ("cases", "Cases", totals.get("cases", 0)),
        ("source_cases", "Source", totals.get("source_cases", 0)),
        ("usage_cases", "Usage", totals.get("usage_cases", 0)),
        ("passed", "Passed", totals.get("passed", 0)),
        ("failed", "Failed", totals.get("failed", 0)),
        ("casts", "Casts", f"{cast_total} ({cast_coverage})"),
    ]
    return "\n".join(
        f'        <div class="metric" data-proof-total="{html.escape(field_name)}">'
        f"<strong>{html.escape(str(value))}</strong><span>{html.escape(label)}</span></div>"
        for field_name, label, value in cards
    )


def _library_cards(site_data: dict[str, Any], *, page_depth: int) -> str:
    cards: list[str] = []
    for library_entry in site_data["proof"]["libraries"]:
        library = str(library_entry["library"])
        totals = library_entry["totals"]
        href = _page_href(f"library/{library}.html", page_depth=page_depth)
        assert href is not None
        cards.append(
            "\n".join(
                [
                    f'        <a class="library-card" href="{html.escape(href)}" data-library-card="{html.escape(library)}">',
                    f"          <strong>{html.escape(library)}</strong>",
                    (
                        "          <span>"
                        f'{html.escape(str(totals["cases"]))} cases, '
                        f'{html.escape(str(totals["passed"]))} passed, '
                        f'{html.escape(str(totals["failed"]))} failed'
                        "</span>"
                    ),
                    "        </a>",
                ]
            )
        )
    return "\n".join(cards)


def _tag_list(tags: Any) -> str:
    if not isinstance(tags, list) or not tags:
        return '<span class="muted">none</span>'
    return " ".join(f"<span>{html.escape(str(tag))}</span>" for tag in tags)


def _case_search_text(row: dict[str, Any]) -> str:
    parts = [
        row.get("library"),
        row.get("testcase_id"),
        row.get("title"),
        row.get("description"),
        row.get("kind"),
        row.get("client_application"),
        " ".join(str(tag) for tag in row.get("tags") or []),
    ]
    return " ".join(str(part) for part in parts if part)


def _case_details(rows: list[dict[str, Any]], *, page_depth: int) -> str:
    rendered_rows: list[str] = []
    for row in rows:
        library = str(row["library"])
        testcase_id = str(row["testcase_id"])
        title = str(row["title"])
        description = str(row["description"])
        kind = str(row["kind"])
        status = str(row["status"])
        client_application = row["client_application"]
        log_href = _page_href(str(row["log_href"]), page_depth=page_depth)
        cast_href = _page_href(row["cast_href"], page_depth=page_depth)
        cast_attr = cast_href or ""
        play_button = (
            f'<button type="button" class="play-button js-load-cast" data-cast="{html.escape(cast_attr)}">Play</button>'
            if cast_href is not None
            else '<span class="muted">No cast</span>'
        )
        rendered_rows.append(
            "\n".join(
                [
                    (
                        f'        <details class="case-row" data-library="{html.escape(library)}" '
                        f'data-testcase-id="{html.escape(testcase_id)}" data-kind="{html.escape(kind)}" '
                        f'data-status="{html.escape(status)}" data-player-cast="{html.escape(cast_attr)}" '
                        f'data-search="{html.escape(_case_search_text(row))}">'
                    ),
                    "          <summary>",
                    '            <span class="case-title">',
                    f"              <strong>{html.escape(title)}</strong>",
                    f'              <span class="case-id">{html.escape(library)} / {html.escape(testcase_id)}</span>',
                    "            </span>",
                    (
                        f'            <span class="status-pill status-{html.escape(status)}">'
                        f"{html.escape(_status_label(status))}</span>"
                    ),
                    "          </summary>",
                    '          <div class="case-body">',
                    f"            <p>{html.escape(description)}</p>",
                    '            <dl class="case-meta">',
                    f"              <div><dt>Kind</dt><dd>{html.escape(kind)}</dd></div>",
                    (
                        "              <div><dt>Client</dt><dd>"
                        f"{html.escape(str(client_application)) if client_application is not None else 'none'}"
                        "</dd></div>"
                    ),
                    f"              <div><dt>Duration</dt><dd>{html.escape(_format_duration(row['duration_seconds']))}</dd></div>",
                    f'              <div><dt>Tags</dt><dd class="tags">{_tag_list(row["tags"])}</dd></div>',
                    "            </dl>",
                    '            <div class="case-actions">',
                    f'              <a class="log-link" href="{html.escape(str(log_href))}">Log</a>',
                    f"              {play_button}",
                    "            </div>",
                    '            <div class="cast-player" data-player>',
                    '              <div class="player-controls">',
                    '                <button type="button" class="js-player-play">Play</button>',
                    '                <button type="button" class="js-player-pause">Pause</button>',
                    '                <button type="button" class="js-player-restart">Restart</button>',
                    '                <label>Speed <select class="js-player-speed"><option value="0.5">0.5x</option><option value="1" selected>1x</option><option value="2">2x</option><option value="4">4x</option></select></label>',
                    '                <label class="scrub-label">Position <input class="js-player-scrub" type="range" min="0" max="1000" value="0"></label>',
                    "              </div>",
                    '              <pre class="terminal" aria-live="polite"></pre>',
                    "            </div>",
                    "          </div>",
                    "        </details>",
                ]
            )
        )
    return "\n".join(rendered_rows)


def _filters() -> str:
    return "\n".join(
        [
            '      <section class="controls" aria-label="Testcase filters">',
            '        <label class="search-label">Search <input id="search-input" type="search" autocomplete="off"></label>',
            '        <label>Status <select id="status-filter"><option value="all">All</option><option value="passed">Passed</option><option value="failed">Failed</option></select></label>',
            '        <label>Kind <select id="kind-filter"><option value="all">All</option><option value="source">Source</option><option value="usage">Usage</option></select></label>',
            "      </section>",
        ]
    )


def render_page(
    site_data: dict[str, Any],
    *,
    page_depth: int = 0,
    current_library: str | None = None,
) -> str:
    rows = list(site_data["testcases"])
    if current_library is not None:
        rows = [row for row in rows if row["library"] == current_library]
    title = "Original Library Validation"
    if current_library is not None:
        title = f"{current_library} Validation"
    css_href = _page_href("assets/site.css", page_depth=page_depth)
    js_href = _page_href("assets/player.js", page_depth=page_depth)
    data_href = _page_href("site-data.json", page_depth=page_depth)
    assert css_href is not None and js_href is not None and data_href is not None

    library_section = ""
    if current_library is None:
        library_section = "\n".join(
            [
                '      <section class="library-overview" aria-label="Library summaries">',
                "        <h2>Libraries</h2>",
                '        <div class="library-grid">',
                _library_cards(site_data, page_depth=page_depth),
                "        </div>",
                "      </section>",
            ]
        )

    return "\n".join(
        [
            "<!doctype html>",
            '<html lang="en">',
            "  <head>",
            '    <meta charset="utf-8">',
            '    <meta name="viewport" content="width=device-width, initial-scale=1">',
            f"    <title>{html.escape(title)}</title>",
            '    <link rel="icon" href="data:,">',
            f'    <link rel="stylesheet" href="{html.escape(css_href)}">',
            f'    <script defer src="{html.escape(js_href)}"></script>',
            "  </head>",
            f'  <body data-site-data="{html.escape(data_href)}">',
            "    <main>",
            '      <section class="dashboard" aria-label="Validation dashboard">',
            f"        <h1>{html.escape(title)}</h1>",
            '        <div class="metric-grid">',
            _summary_cards(site_data),
            "        </div>",
            "      </section>",
            library_section,
            _filters(),
            '      <section class="testcases" aria-label="Testcases">',
            "        <h2>Testcases</h2>",
            _case_details(rows, page_depth=page_depth),
            "      </section>",
            "    </main>",
            "  </body>",
            "</html>",
            "",
        ]
    )


SITE_CSS = """
:root {
  color-scheme: light;
  font-family: Inter, "Segoe UI", Arial, sans-serif;
  color: #18201f;
  background: #f6f7f4;
}

* { box-sizing: border-box; }

body {
  margin: 0;
  background: #f6f7f4;
}

main {
  width: min(1180px, calc(100% - 32px));
  margin: 0 auto;
  padding: 24px 0 48px;
}

h1, h2, p { margin-top: 0; }

h1 {
  font-size: 2.25rem;
  line-height: 1.08;
  margin-bottom: 18px;
}

h2 {
  font-size: 1.25rem;
  margin: 0 0 14px;
}

.dashboard {
  padding: 16px 0 20px;
}

.metric-grid,
.library-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
  gap: 10px;
}

.metric,
.library-card {
  border: 1px solid #d8ddd6;
  border-radius: 8px;
  background: #ffffff;
  padding: 14px;
}

.metric strong,
.library-card strong {
  display: block;
  color: #0f3b34;
  font-size: 1.45rem;
  line-height: 1.1;
  overflow-wrap: anywhere;
}

.metric span,
.library-card span {
  display: block;
  color: #59635f;
  font-size: 0.9rem;
  margin-top: 5px;
}

.library-card {
  color: inherit;
  text-decoration: none;
}

.library-card:hover,
.library-card:focus-visible {
  border-color: #4f7f78;
  outline: none;
}

.library-overview,
.controls,
.testcases {
  margin-top: 24px;
}

.controls {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  align-items: end;
  padding: 12px;
  border: 1px solid #d8ddd6;
  border-radius: 8px;
  background: #ffffff;
}

label {
  display: grid;
  gap: 5px;
  color: #4d5753;
  font-size: 0.9rem;
}

.search-label {
  flex: 1 1 260px;
}

input,
select,
button,
.log-link {
  min-height: 38px;
  border-radius: 6px;
  font: inherit;
}

input,
select {
  border: 1px solid #bfc8c3;
  background: #fbfcfa;
  color: #18201f;
  padding: 7px 9px;
}

button,
.log-link {
  border: 1px solid #24524c;
  background: #24524c;
  color: #ffffff;
  padding: 8px 12px;
  cursor: pointer;
  text-decoration: none;
}

button:hover,
button:focus-visible,
.log-link:hover,
.log-link:focus-visible {
  background: #163a35;
  outline: none;
}

.case-row {
  border: 1px solid #d8ddd6;
  border-radius: 8px;
  background: #ffffff;
  margin-bottom: 10px;
  overflow: hidden;
}

.case-row[hidden] {
  display: none;
}

.case-row summary {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  gap: 12px;
  align-items: center;
  cursor: pointer;
  padding: 14px;
}

.case-title strong,
.case-id {
  display: block;
  overflow-wrap: anywhere;
}

.case-title strong {
  font-size: 1rem;
}

.case-id,
.muted {
  color: #66716d;
  font-size: 0.88rem;
}

.status-pill {
  border-radius: 999px;
  padding: 5px 9px;
  font-size: 0.82rem;
  font-weight: 700;
}

.status-passed {
  background: #dcefe5;
  color: #155b36;
}

.status-failed {
  background: #f8ded9;
  color: #8a2a1d;
}

.case-body {
  border-top: 1px solid #edf0ec;
  padding: 14px;
}

.case-body p {
  line-height: 1.5;
  margin-bottom: 12px;
}

.case-meta {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  gap: 10px;
  margin: 0 0 14px;
}

.case-meta div {
  min-width: 0;
}

.case-meta dt {
  color: #66716d;
  font-size: 0.8rem;
}

.case-meta dd {
  margin: 3px 0 0;
  overflow-wrap: anywhere;
}

.tags span {
  display: inline-block;
  margin: 0 5px 5px 0;
  border-radius: 999px;
  background: #edf0ec;
  padding: 3px 7px;
  font-size: 0.82rem;
}

.case-actions,
.player-controls {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  align-items: center;
}

.cast-player {
  margin-top: 12px;
}

.player-controls {
  margin-bottom: 8px;
}

.scrub-label {
  flex: 1 1 220px;
}

.terminal {
  height: 230px;
  max-height: 42vh;
  overflow: auto;
  margin: 0;
  border-radius: 8px;
  background: #111817;
  color: #e7f0ec;
  padding: 12px;
  white-space: pre-wrap;
  overflow-wrap: anywhere;
  font-family: "SFMono-Regular", Consolas, monospace;
  font-size: 0.9rem;
  line-height: 1.45;
}

@media (max-width: 620px) {
  main {
    width: min(100% - 20px, 1180px);
    padding-top: 16px;
  }

  h1 {
    font-size: 1.8rem;
  }

  .case-row summary {
    grid-template-columns: 1fr;
  }

  .controls {
    align-items: stretch;
  }

  label,
  .search-label {
    flex: 1 1 100%;
  }
}
""".strip() + "\n"


PLAYER_JS = r"""
(() => {
  const rows = Array.from(document.querySelectorAll(".case-row"));
  const searchInput = document.getElementById("search-input");
  const statusFilter = document.getElementById("status-filter");
  const kindFilter = document.getElementById("kind-filter");

  function applyFilters() {
    const query = (searchInput?.value || "").trim().toLowerCase();
    const status = statusFilter?.value || "all";
    const kind = kindFilter?.value || "all";
    for (const row of rows) {
      const matchesQuery = !query || (row.dataset.search || "").toLowerCase().includes(query);
      const matchesStatus = status === "all" || row.dataset.status === status;
      const matchesKind = kind === "all" || row.dataset.kind === kind;
      row.hidden = !(matchesQuery && matchesStatus && matchesKind);
    }
  }

  searchInput?.addEventListener("input", applyFilters);
  statusFilter?.addEventListener("change", applyFilters);
  kindFilter?.addEventListener("change", applyFilters);

  class CastPlayer {
    constructor(root, castHref) {
      this.root = root;
      this.castHref = castHref;
      this.terminal = root.querySelector(".terminal");
      this.playButton = root.querySelector(".js-player-play");
      this.pauseButton = root.querySelector(".js-player-pause");
      this.restartButton = root.querySelector(".js-player-restart");
      this.speedSelect = root.querySelector(".js-player-speed");
      this.scrub = root.querySelector(".js-player-scrub");
      this.events = [];
      this.loaded = false;
      this.playing = false;
      this.timer = null;
      this.index = 0;
      this.startedAt = 0;
      this.offset = 0;

      this.playButton?.addEventListener("click", () => this.play());
      this.pauseButton?.addEventListener("click", () => this.pause());
      this.restartButton?.addEventListener("click", () => this.restart());
      this.scrub?.addEventListener("input", () => this.seekFromScrub());
    }

    async load() {
      if (this.loaded) return;
      this.terminal.textContent = "Loading cast...\n";
      const response = await fetch(this.castHref);
      if (!response.ok) throw new Error(`Unable to load cast: ${response.status}`);
      const text = await response.text();
      const lines = text.trimEnd().split(/\n/);
      lines.shift();
      this.events = lines.map((line) => JSON.parse(line)).filter((event) => event[1] === "o");
      this.loaded = true;
      this.index = 0;
      this.offset = 0;
      this.terminal.textContent = "";
      this.updateScrub();
    }

    speed() {
      const value = Number(this.speedSelect?.value || 1);
      return Number.isFinite(value) && value > 0 ? value : 1;
    }

    duration() {
      if (!this.events.length) return 0;
      return Number(this.events[this.events.length - 1][0]) || 0;
    }

    updateScrub() {
      if (!this.scrub) return;
      const total = this.duration();
      const position = this.index <= 0 ? 0 : Number(this.events[Math.min(this.index - 1, this.events.length - 1)][0]) || 0;
      this.scrub.value = total <= 0 ? "0" : String(Math.round((position / total) * 1000));
    }

    renderUntil(targetSeconds) {
      this.terminal.textContent = "";
      this.index = 0;
      while (this.index < this.events.length && Number(this.events[this.index][0]) <= targetSeconds) {
        this.terminal.textContent += String(this.events[this.index][2]);
        this.index += 1;
      }
      this.terminal.scrollTop = this.terminal.scrollHeight;
      this.offset = targetSeconds;
      this.updateScrub();
    }

    seekFromScrub() {
      const total = this.duration();
      const value = Number(this.scrub?.value || 0);
      const target = total * (value / 1000);
      const wasPlaying = this.playing;
      this.pause();
      this.renderUntil(target);
      if (wasPlaying) this.play();
    }

    schedule() {
      if (!this.playing) return;
      if (this.index >= this.events.length) {
        this.pause();
        return;
      }
      const nextTime = Number(this.events[this.index][0]) || 0;
      const elapsed = ((performance.now() - this.startedAt) / 1000) * this.speed();
      const delay = Math.max(0, ((nextTime - this.offset - elapsed) / this.speed()) * 1000);
      this.timer = window.setTimeout(() => {
        if (!this.playing) return;
        this.terminal.textContent += String(this.events[this.index][2]);
        this.terminal.scrollTop = this.terminal.scrollHeight;
        this.index += 1;
        this.updateScrub();
        this.schedule();
      }, delay);
    }

    async play() {
      await this.load();
      if (this.playing) return;
      this.playing = true;
      this.startedAt = performance.now();
      this.schedule();
    }

    pause() {
      if (this.timer !== null) window.clearTimeout(this.timer);
      this.timer = null;
      if (this.playing) {
        const elapsed = ((performance.now() - this.startedAt) / 1000) * this.speed();
        this.offset += elapsed;
      }
      this.playing = false;
    }

    async restart() {
      this.pause();
      await this.load();
      this.index = 0;
      this.offset = 0;
      this.terminal.textContent = "";
      this.updateScrub();
      this.play();
    }
  }

  document.querySelectorAll(".js-load-cast").forEach((button) => {
    button.addEventListener("click", async () => {
      const row = button.closest(".case-row");
      const playerRoot = row?.querySelector("[data-player]");
      const castHref = button.dataset.cast;
      if (!row || !playerRoot || !castHref) return;
      row.open = true;
      if (!playerRoot.castPlayer) {
        playerRoot.castPlayer = new CastPlayer(playerRoot, castHref);
      }
      try {
        await playerRoot.castPlayer.restart();
      } catch (error) {
        const terminal = playerRoot.querySelector(".terminal");
        if (terminal) terminal.textContent = `${error.message}\n`;
      }
    });
  });
})();
""".strip() + "\n"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", required=True, type=Path)
    parser.add_argument("--tests-root", required=True, type=Path)
    parser.add_argument("--artifact-root", required=True, type=Path)
    parser.add_argument("--proof-path", required=True, type=Path)
    parser.add_argument("--output-root", required=True, type=Path)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    artifact_root = args.artifact_root.resolve(strict=False)
    output_root = args.output_root.resolve(strict=False)
    proof_data = load_proof(args.proof_path, artifact_root=artifact_root)
    validate_proof_matches_artifacts(
        proof_data,
        config_path=args.config,
        tests_root=args.tests_root,
        artifact_root=artifact_root,
    )

    reset_dir(output_root)
    site_data = build_site_data(
        proof_data,
        artifact_root=artifact_root,
        output_root=output_root,
        copy_evidence=True,
    )
    if tuple(site_data.keys()) != SITE_DATA_KEYS:
        raise ValidatorError("site-data.json shape mismatch")

    write_json(output_root / "site-data.json", site_data)
    (output_root / "index.html").write_text(render_page(site_data), encoding="utf-8")
    assets_root = output_root / "assets"
    assets_root.mkdir(parents=True, exist_ok=True)
    (assets_root / "site.css").write_text(SITE_CSS, encoding="utf-8")
    (assets_root / "player.js").write_text(PLAYER_JS, encoding="utf-8")

    library_root = output_root / "library"
    library_root.mkdir(parents=True, exist_ok=True)
    for library in selected_libraries_from_proof(proof_data):
        target = _resolve_inside(library_root, library_root / f"{library}.html", description="library page")
        target.write_text(
            render_page(site_data, page_depth=1, current_library=library),
            encoding="utf-8",
        )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ValidatorError as exc:
        print(str(exc), file=sys.stderr)
        raise SystemExit(1)
