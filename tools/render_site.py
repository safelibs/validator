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


SITE_DATA_KEYS = ("schema_version", "proofs", "testcases")
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


def _evidence_href(*, mode: str, kind: str, library: str, testcase_id: str, suffix: str) -> str:
    mode_component = _safe_site_component(mode, field_name="mode")
    library_component = _safe_site_component(library, field_name="library")
    testcase_component = _safe_site_component(testcase_id, field_name="testcase_id")
    return f"evidence/{mode_component}/{kind}/{library_component}/{testcase_component}.{suffix}"


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
    if proof_data.get("mode") not in {"original", "port-04-test"}:
        raise ValidatorError(f"proof manifest mode must be original or port-04-test: {proof_path}")
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


def _without_unsafe_blocks(proof_data: dict[str, Any]) -> dict[str, Any]:
    stripped = {k: v for k, v in proof_data.items() if k != "unsafe_blocks"}
    libraries = stripped.get("libraries")
    if isinstance(libraries, list):
        stripped["libraries"] = [
            {k: v for k, v in entry.items() if k != "unsafe_blocks"}
            if isinstance(entry, dict)
            else entry
            for entry in libraries
        ]
    return stripped


def validate_proof_matches_artifacts(
    proof_data: dict[str, Any],
    *,
    config_path: Path,
    tests_root: Path,
    artifact_root: Path,
) -> None:
    manifest = load_manifest(config_path)
    selected_libraries = selected_libraries_from_proof(proof_data)
    mode = str(proof_data.get("mode"))
    expected_proof = proof_tools.build_proof(
        manifest,
        artifact_root=artifact_root,
        tests_root=tests_root,
        mode=mode,
        libraries=selected_libraries,
        require_casts=False,
    )
    if _without_unsafe_blocks(expected_proof) != _without_unsafe_blocks(proof_data):
        raise ValidatorError("proof manifest does not match rebuilt proof")


def build_site_data(
    proof_data: dict[str, Any] | list[dict[str, Any]],
    *,
    artifact_root: Path,
    output_root: Path,
    copy_evidence: bool = False,
) -> dict[str, Any]:
    proofs_input = [proof_data] if isinstance(proof_data, dict) else list(proof_data)
    if not proofs_input:
        raise ValidatorError("site rendering requires at least one proof")

    artifact_root = artifact_root.resolve(strict=False)
    output_root = output_root.resolve(strict=False)
    site_proofs = [copy.deepcopy(proof) for proof in proofs_input]
    rows: list[dict[str, Any]] = []
    seen_modes: set[str] = set()

    for site_proof in site_proofs:
        if site_proof.get("proof_version") != 2:
            raise ValidatorError("site rendering requires proof_version 2")
        mode = _safe_site_component(site_proof.get("mode"), field_name="mode")
        if mode in seen_modes:
            raise ValidatorError(f"proof modes must be unique: {mode}")
        seen_modes.add(mode)

        for library_entry in _proof_libraries(site_proof):
            library = _safe_site_component(library_entry.get("library"), field_name="library")
            testcases = _require_list(library_entry.get("testcases"), field_name=f"{library} testcases")
            for raw_case in testcases:
                case = _require_dict(raw_case, field_name=f"{library} testcase")
                testcase_id = _safe_site_component(case.get("testcase_id"), field_name="testcase_id")
                case_mode = _safe_site_component(case.get("mode"), field_name="mode")
                if case_mode != mode:
                    raise ValidatorError(f"testcase mode must match proof mode for {library}/{testcase_id}")

                log_path = case.get("log_path")
                if not isinstance(log_path, str) or not log_path:
                    raise ValidatorError(f"log_path must be present for {library}/{testcase_id}")
                log_source = proof_tools.validate_artifact_relative_path(
                    log_path,
                    field_name="log_path",
                    artifacts_root=artifact_root,
                    source_path=Path(f"proof:{mode}/{library}/{testcase_id}"),
                )
                assert log_source is not None
                if not log_source.is_file():
                    raise ValidatorError(f"proof log_path does not exist: {log_path}")
                log_href = _evidence_href(
                    mode=mode,
                    kind="logs",
                    library=library,
                    testcase_id=testcase_id,
                    suffix="log",
                )
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
                        source_path=Path(f"proof:{mode}/{library}/{testcase_id}"),
                    )
                    assert cast_source is not None
                    if not cast_source.is_file():
                        raise ValidatorError(f"proof cast_path does not exist: {cast_path}")
                    cast_href = _evidence_href(
                        mode=mode,
                        kind="casts",
                        library=library,
                        testcase_id=testcase_id,
                        suffix="cast",
                    )
                    if copy_evidence:
                        _copy_evidence(source=cast_source, output_root=output_root, href=cast_href)
                case["cast_href"] = cast_href

                row = {key: case.get(key) for key in TESTCASE_ROW_KEYS}
                row["library"] = library
                row["mode"] = mode
                if set(row) != set(TESTCASE_ROW_KEYS):
                    raise ValidatorError("internal testcase row shape mismatch")
                rows.append(row)

    return {
        "schema_version": 2,
        "proofs": site_proofs,
        "testcases": rows,
    }


def _status_label(status: str) -> str:
    return "Passed" if status == "passed" else "Failed"


def _format_duration(value: Any) -> str:
    if isinstance(value, (int, float)):
        return f"{float(value):.2f}s"
    return str(value)


def _mode_label(mode: str) -> str:
    return {
        "original": "Original",
        "port-04-test": "Port",
    }.get(mode, mode)


def _scoped_rows(site_data: dict[str, Any], *, current_library: str | None = None) -> list[dict[str, Any]]:
    rows = list(site_data["testcases"])
    if current_library is not None:
        rows = [row for row in rows if row["library"] == current_library]
    return rows


def _inventory_counts(rows: list[dict[str, Any]]) -> dict[str, int]:
    libraries: set[str] = set()
    testcases: dict[tuple[str, str], dict[str, Any]] = {}
    for row in rows:
        library = str(row["library"])
        libraries.add(library)
        key = (library, str(row["testcase_id"]))
        testcases.setdefault(key, row)
    return {
        "libraries": len(libraries),
        "cases": len(testcases),
        "source_cases": sum(1 for row in testcases.values() if row["kind"] == "source"),
        "usage_cases": sum(1 for row in testcases.values() if row["kind"] == "usage"),
    }


def _port_counts(rows: list[dict[str, Any]]) -> dict[str, int]:
    port_rows = [row for row in rows if row["mode"] == "port-04-test"]
    by_library: dict[str, list[dict[str, Any]]] = {}
    for row in port_rows:
        by_library.setdefault(str(row["library"]), []).append(row)
    passed = sum(1 for row in port_rows if row["status"] == "passed")
    return {
        "cases": len(port_rows),
        "passed": passed,
        "failed": len(port_rows) - passed,
        "libraries": len(by_library),
        "passing_libraries": sum(
            1
            for library_rows in by_library.values()
            if library_rows and all(row["status"] == "passed" for row in library_rows)
        ),
    }


def _ratio_text(numerator: int, denominator: int, *, empty: str = "Not run") -> str:
    if denominator == 0:
        return empty
    return f"{numerator} / {denominator}"


def _summary_cards(site_data: dict[str, Any], *, current_library: str | None = None) -> str:
    rows = _scoped_rows(site_data, current_library=current_library)
    inventory = _inventory_counts(rows)
    ports = _port_counts(rows)
    cast_total = sum(1 for row in rows if row.get("cast_href") is not None)
    cast_coverage = "0%" if not rows else f"{round((cast_total / len(rows)) * 100):d}%"
    totals = {
        "libraries": inventory["libraries"],
        "cases": inventory["cases"],
        "source_cases": inventory["source_cases"],
        "usage_cases": inventory["usage_cases"],
        "passed": ports["passed"],
        "failed": ports["failed"],
        "casts": cast_total,
    }
    cards = [
        ("libraries", "Libraries", totals["libraries"]),
        ("cases", "Tests", totals["cases"]),
        ("source_cases", "Source tests", totals["source_cases"]),
        ("usage_cases", "Usage tests", totals["usage_cases"]),
        ("passed", "Port tests passing", _ratio_text(ports["passed"], ports["cases"])),
        ("failed", "Port tests failing", ports["failed"] if ports["cases"] else "Not run"),
        ("casts", "Evidence casts", f"{cast_total} ({cast_coverage})"),
        (
            "port_libraries",
            "Port libraries passing",
            _ratio_text(ports["passing_libraries"], ports["libraries"]),
        ),
    ]
    return "\n".join(
        f'        <div class="metric" data-proof-total="{html.escape(field_name)}">'
        f"<strong>{html.escape(str(value))}</strong><span>{html.escape(label)}</span></div>"
        for field_name, label, value in cards
    )


_LIBRARY_GROUP_ORDER = (
    ("failing", "Failing"),
    ("passing", "Passing"),
    ("not-run", "Not run"),
)


def _port_library_entry(site_data: dict[str, Any], library: str) -> dict[str, Any] | None:
    for proof_data in site_data["proofs"]:
        if proof_data.get("mode") != "port-04-test":
            continue
        for entry in _proof_libraries(proof_data):
            if str(entry.get("library")) == library:
                return entry
    return None


def _strip_tag_ref(tag_ref: str) -> str:
    prefix = "refs/tags/"
    return tag_ref[len(prefix):] if tag_ref.startswith(prefix) else tag_ref


def _port_provenance_block(site_data: dict[str, Any], library: str) -> str:
    entry = _port_library_entry(site_data, library)
    if entry is None:
        return ""
    repository = entry.get("port_repository")
    if not isinstance(repository, str) or not repository:
        return ""
    repo_url = f"https://github.com/{repository}"
    unavailable = entry.get("port_unavailable_reason")
    if isinstance(unavailable, str) and unavailable:
        return "\n".join(
            [
                '        <p class="port-provenance port-provenance-unavailable">',
                f"          Port unavailable for <a href=\"{html.escape(repo_url)}\">{html.escape(repository)}</a>: "
                f"{html.escape(unavailable)}",
                "        </p>",
            ]
        )
    commit = entry.get("port_commit")
    tag_ref = entry.get("port_tag_ref")
    release_tag = entry.get("port_release_tag")
    if not (isinstance(commit, str) and isinstance(tag_ref, str) and isinstance(release_tag, str)):
        return ""
    tag_name = _strip_tag_ref(tag_ref)
    commit_url = f"{repo_url}/commit/{commit}"
    tag_url = f"{repo_url}/releases/tag/{tag_name}"
    release_url = f"{repo_url}/releases/tag/{release_tag}"
    return "\n".join(
        [
            '        <p class="port-provenance">',
            f"          Port build from <a href=\"{html.escape(repo_url)}\">{html.escape(repository)}</a>"
            f" at commit <a href=\"{html.escape(commit_url)}\"><code>{html.escape(commit[:12])}</code></a>"
            f" (phase tag <a href=\"{html.escape(tag_url)}\"><code>{html.escape(tag_name)}</code></a>,"
            f" release <a href=\"{html.escape(release_url)}\"><code>{html.escape(release_tag)}</code></a>)",
            "        </p>",
        ]
    )


def _library_card(
    library: str,
    rows: list[dict[str, Any]],
    *,
    page_depth: int,
) -> tuple[str, str]:
    inventory = _inventory_counts(rows)
    ports = _port_counts(rows)
    state = "not-run"
    state_label = "Not run"
    if ports["cases"] > 0:
        state = "passing" if ports["failed"] == 0 else "failing"
        state_label = "Passing" if ports["failed"] == 0 else "Failing"
    href = _page_href(f"library/{library}.html", page_depth=page_depth)
    assert href is not None
    port_ratio = _ratio_text(ports["passed"], ports["cases"])
    aria_label = f"{library}: {inventory['cases']} tests, {port_ratio} port tests passing"
    card = "\n".join(
        [
            (
                f'          <a class="library-card library-{html.escape(state)}" '
                f'href="{html.escape(href)}" data-library-card="{html.escape(library)}" '
                f'aria-label="{html.escape(aria_label)}">'
            ),
            '            <span class="library-card-heading">',
            f"              <strong>{html.escape(library)}</strong>",
            f'              <span class="library-state">{html.escape(state_label)}</span>',
            "            </span>",
            '            <dl class="library-stats">',
            f'              <div><dt>Tests</dt><dd>{html.escape(str(inventory["cases"]))}</dd></div>',
            f'              <div><dt>Source</dt><dd>{html.escape(str(inventory["source_cases"]))}</dd></div>',
            f'              <div><dt>Usage</dt><dd>{html.escape(str(inventory["usage_cases"]))}</dd></div>',
            f"              <div><dt>Port pass</dt><dd>{html.escape(port_ratio)}</dd></div>",
            "            </dl>",
            "          </a>",
        ]
    )
    return state, card


def _library_groups(site_data: dict[str, Any], *, page_depth: int) -> str:
    library_rows: dict[str, list[dict[str, Any]]] = {}
    for row in site_data["testcases"]:
        library_rows.setdefault(str(row["library"]), []).append(row)
    grouped: dict[str, list[str]] = {state: [] for state, _ in _LIBRARY_GROUP_ORDER}
    for library in sorted(library_rows):
        state, card = _library_card(library, library_rows[library], page_depth=page_depth)
        grouped[state].append(card)
    sections: list[str] = []
    for state, label in _LIBRARY_GROUP_ORDER:
        cards = grouped[state]
        if not cards:
            continue
        heading_id = f"library-group-{state}-heading"
        sections.append(
            "\n".join(
                [
                    (
                        f'        <div class="library-group library-group-{html.escape(state)}" '
                        f'aria-labelledby="{html.escape(heading_id)}">'
                    ),
                    (
                        f'          <h3 id="{html.escape(heading_id)}" class="library-group-heading">'
                        f"{html.escape(label)} <span class=\"library-group-count\">{len(cards)}</span></h3>"
                    ),
                    '          <div class="library-grid">',
                    *cards,
                    "          </div>",
                    "        </div>",
                ]
            )
        )
    return "\n".join(sections)


def _tag_list(tags: Any) -> str:
    if not isinstance(tags, list) or not tags:
        return '<span class="muted">none</span>'
    return " ".join(f"<span>{html.escape(str(tag))}</span>" for tag in tags)


def _case_search_text(row: dict[str, Any]) -> str:
    parts = [
        row.get("library"),
        row.get("testcase_id"),
        row.get("mode"),
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
        mode = str(row["mode"])
        title = str(row["title"])
        description = str(row["description"])
        kind = str(row["kind"])
        status = str(row["status"])
        client_application = row["client_application"]
        log_href = _page_href(str(row["log_href"]), page_depth=page_depth)
        cast_href = _page_href(row["cast_href"], page_depth=page_depth)
        cast_attr = cast_href or ""
        case_label = f"{_mode_label(mode)} / {library} / {testcase_id}"
        play_button = (
            (
                f'<button type="button" class="play-button js-load-cast" '
                f'data-cast="{html.escape(cast_attr)}" '
                f'aria-label="Play cast for {html.escape(case_label)}">Play</button>'
            )
            if cast_href is not None
            else '<span class="muted">No cast</span>'
        )
        rendered_rows.append(
            "\n".join(
                [
                    (
                        f'        <details class="case-row" data-library="{html.escape(library)}" '
                        f'data-testcase-id="{html.escape(testcase_id)}" data-mode="{html.escape(mode)}" '
                        f'data-kind="{html.escape(kind)}" '
                        f'data-status="{html.escape(status)}" data-player-cast="{html.escape(cast_attr)}" '
                        f'data-search="{html.escape(_case_search_text(row))}">'
                    ),
                    "          <summary>",
                    '            <span class="case-title">',
                    f"              <strong>{html.escape(title)}</strong>",
                    f'              <span class="case-id">{html.escape(case_label)}</span>',
                    "            </span>",
                    (
                        f'            <span class="status-pill status-{html.escape(status)}" '
                        f'aria-label="{html.escape(case_label)} status: {html.escape(_status_label(status))}">'
                        f"{html.escape(_status_label(status))}</span>"
                    ),
                    "          </summary>",
                    '          <div class="case-body">',
                    f"            <p>{html.escape(description)}</p>",
                    '            <dl class="case-meta">',
                    f"              <div><dt>Run</dt><dd>{html.escape(_mode_label(mode))}</dd></div>",
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
                    (
                        f'              <a class="log-link" href="{html.escape(str(log_href))}" '
                        f'aria-label="Open log for {html.escape(case_label)}">Log</a>'
                    ),
                    f"              {play_button}",
                    "            </div>",
                    '            <div class="cast-player" data-player>',
                    '              <div class="player-controls">',
                    f'                <button type="button" class="js-player-play" aria-label="Play cast playback for {html.escape(case_label)}">Play</button>',
                    f'                <button type="button" class="js-player-pause" aria-label="Pause cast playback for {html.escape(case_label)}">Pause</button>',
                    f'                <button type="button" class="js-player-restart" aria-label="Restart cast playback for {html.escape(case_label)}">Restart</button>',
                    '                <label>Speed <select class="js-player-speed"><option value="0.5">0.5x</option><option value="1" selected>1x</option><option value="2">2x</option><option value="4">4x</option></select></label>',
                    '                <label class="scrub-label">Position <input class="js-player-scrub" type="range" min="0" max="1000" value="0"></label>',
                    "              </div>",
                    f'              <pre class="terminal" aria-live="polite" aria-label="Cast output for {html.escape(case_label)}"></pre>',
                    "            </div>",
                    "          </div>",
                    "        </details>",
                ]
            )
        )
    return "\n".join(rendered_rows)


def _filters(site_data: dict[str, Any]) -> str:
    mode_options = ['<option value="all">All</option>']
    for proof in site_data["proofs"]:
        mode = str(proof["mode"])
        mode_options.append(f'<option value="{html.escape(mode)}">{html.escape(_mode_label(mode))}</option>')
    return "\n".join(
        [
            '      <section class="controls" aria-label="Testcase filters">',
            '        <label class="search-label">Search <input id="search-input" type="search" autocomplete="off" name="search"></label>',
            f'        <label>Run mode <select id="mode-filter" name="mode">{"".join(mode_options)}</select></label>',
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
    rows = _scoped_rows(site_data, current_library=current_library)
    title = "Library Validation Matrix"
    if current_library is not None:
        title = f"{current_library} Validation"
    css_href = _page_href("assets/site.css", page_depth=page_depth)
    js_href = _page_href("assets/player.js", page_depth=page_depth)
    data_href = _page_href("site-data.json", page_depth=page_depth)
    assert css_href is not None and js_href is not None and data_href is not None
    index_href = _page_href("index.html", page_depth=page_depth)

    library_section = ""
    if current_library is None:
        library_section = "\n".join(
            [
                '      <section class="library-overview" aria-labelledby="libraries-heading">',
                '        <h2 id="libraries-heading">Libraries and Port Status</h2>',
                _library_groups(site_data, page_depth=page_depth),
                "      </section>",
            ]
        )
    breadcrumb = ""
    if current_library is not None:
        assert index_href is not None
        breadcrumb = f'      <nav class="breadcrumb" aria-label="Breadcrumb"><a href="{html.escape(index_href)}">All libraries</a></nav>'

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
            '    <a class="skip-link" href="#tests-heading">Skip to tests</a>',
            "    <main>",
            breadcrumb,
            '      <section class="dashboard" aria-labelledby="dashboard-heading">',
            f'        <h1 id="dashboard-heading">{html.escape(title)}</h1>',
            *(
                [_port_provenance_block(site_data, current_library)]
                if current_library is not None
                else []
            ),
            '        <div class="metric-grid">',
            _summary_cards(site_data, current_library=current_library),
            "        </div>",
            "      </section>",
            library_section,
            _filters(site_data),
            '      <section id="testcases" class="testcases" aria-labelledby="tests-heading">',
            '        <h2 id="tests-heading">Tests</h2>',
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
  background: #f7f8f6;
  --page: #f7f8f6;
  --surface: #ffffff;
  --surface-muted: #eef2ef;
  --border: #d7dfda;
  --border-strong: #aebbb4;
  --text: #18201f;
  --muted: #4f5d58;
  --accent: #1f6677;
  --accent-strong: #164958;
  --focus: #b46300;
  --success-bg: #dcefe6;
  --success-text: #145633;
  --danger-bg: #f7ddd7;
  --danger-text: #842719;
  --warning-bg: #fff2c2;
  --warning-text: #624300;
}

* { box-sizing: border-box; }

body {
  margin: 0;
  background: var(--page);
}

a {
  color: var(--accent);
}

.skip-link {
  position: absolute;
  top: -48px;
  left: 16px;
  z-index: 10;
  border-radius: 6px;
  background: var(--accent-strong);
  color: #ffffff;
  padding: 10px 12px;
}

.skip-link:focus {
  top: 12px;
}

main {
  width: min(1220px, calc(100% - 32px));
  margin: 0 auto;
  padding: 32px 0 56px;
}

h1, h2, p { margin-top: 0; }

h1 {
  max-width: 760px;
  font-size: 2.35rem;
  line-height: 1.1;
  margin-bottom: 20px;
}

h2 {
  font-size: 1.25rem;
  margin: 0 0 14px;
}

.breadcrumb {
  margin-bottom: 18px;
}

.breadcrumb a {
  display: inline-flex;
  align-items: center;
  min-height: 38px;
  border: 1px solid var(--border);
  border-radius: 6px;
  background: var(--surface);
  padding: 8px 12px;
  text-decoration: none;
}

.dashboard {
  padding: 14px 0 24px;
  border-bottom: 1px solid var(--border);
}

.port-provenance {
  margin: 4px 0 16px;
  color: var(--muted);
  font-size: 0.9rem;
}

.port-provenance code {
  font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
  background: var(--surface-muted);
  padding: 1px 4px;
  border-radius: 3px;
}

.port-provenance-unavailable {
  color: var(--danger-text);
}

.metric-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
  gap: 12px;
}

.library-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: 12px;
}

.metric,
.library-card {
  border: 1px solid var(--border);
  border-radius: 8px;
  background: var(--surface);
}

.metric {
  display: grid;
  align-content: space-between;
  min-height: 108px;
  border-top: 4px solid var(--accent);
  padding: 14px;
}

.metric[data-proof-total="failed"] {
  border-top-color: #aa3a26;
}

.metric[data-proof-total="port_libraries"] {
  border-top-color: #6f5a99;
}

.metric strong {
  display: block;
  color: var(--text);
  font-size: 1.45rem;
  line-height: 1.1;
  overflow-wrap: anywhere;
  white-space: nowrap;
}

.metric span {
  display: block;
  color: var(--muted);
  font-size: 0.9rem;
  margin-top: 8px;
}

.library-card {
  color: inherit;
  display: grid;
  gap: 12px;
  padding: 14px;
  text-decoration: none;
}

.library-card:hover,
.library-card:focus-visible {
  border-color: var(--accent);
  box-shadow: 0 8px 24px rgb(24 32 31 / 8%);
}

.library-card-heading {
  display: flex;
  gap: 10px;
  align-items: start;
  justify-content: space-between;
}

.library-card strong {
  color: var(--text);
  font-size: 1.15rem;
  line-height: 1.2;
  overflow-wrap: anywhere;
}

.library-state {
  flex: 0 0 auto;
  border-radius: 999px;
  padding: 4px 8px;
  font-size: 0.78rem;
  font-weight: 700;
}

.library-passing .library-state {
  background: var(--success-bg);
  color: var(--success-text);
}

.library-failing .library-state {
  background: var(--danger-bg);
  color: var(--danger-text);
}

.library-not-run .library-state {
  background: var(--warning-bg);
  color: var(--warning-text);
}

.library-group + .library-group {
  margin-top: 20px;
}

.library-group-heading {
  display: flex;
  align-items: center;
  gap: 10px;
  margin: 0 0 10px;
  font-size: 1rem;
}

.library-group-count {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 22px;
  padding: 2px 8px;
  border-radius: 999px;
  background: var(--surface-muted);
  color: var(--muted);
  font-size: 0.78rem;
  font-weight: 600;
}

.library-group-failing .library-group-heading {
  color: var(--danger-text);
}

.library-group-failing .library-group-count {
  background: var(--danger-bg);
  color: var(--danger-text);
}

.library-group-passing .library-group-count {
  background: var(--success-bg);
  color: var(--success-text);
}

.library-group-not-run .library-group-count {
  background: var(--warning-bg);
  color: var(--warning-text);
}

.library-failing {
  border-color: var(--danger-text);
  box-shadow: inset 4px 0 0 var(--danger-text);
}

.library-stats,
.case-meta {
  display: grid;
  gap: 10px;
}

.library-stats {
  grid-template-columns: repeat(2, minmax(0, 1fr));
  margin: 0;
}

.library-stats div {
  min-width: 0;
  border: 1px solid var(--border);
  border-radius: 6px;
  background: var(--surface-muted);
  padding: 8px;
}

.library-stats dt,
.case-meta dt {
  color: var(--muted);
  font-size: 0.8rem;
}

.library-stats dd,
.case-meta dd {
  margin: 3px 0 0;
  overflow-wrap: anywhere;
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
  border: 1px solid var(--border);
  border-radius: 8px;
  background: var(--surface);
}

label {
  display: grid;
  gap: 5px;
  color: var(--muted);
  font-size: 0.9rem;
}

.search-label {
  flex: 1 1 300px;
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
  border: 1px solid var(--border-strong);
  background: #fbfcfb;
  color: var(--text);
  padding: 7px 9px;
}

button,
.log-link {
  border: 1px solid var(--accent-strong);
  background: var(--accent-strong);
  color: #ffffff;
  padding: 8px 12px;
  cursor: pointer;
  text-decoration: none;
}

button:hover,
.log-link:hover,
.breadcrumb a:hover {
  background: var(--accent);
  color: #ffffff;
}

button:focus-visible,
.log-link:focus-visible,
.library-card:focus-visible,
.breadcrumb a:focus-visible,
input:focus-visible,
select:focus-visible,
.case-row summary:focus-visible {
  outline: 3px solid var(--focus);
  outline-offset: 2px;
}

.log-link:focus-visible {
  background: var(--accent);
}

.case-row {
  border: 1px solid var(--border);
  border-radius: 8px;
  background: var(--surface);
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
  padding: 15px;
}

.case-row summary:hover {
  background: #fbfcfb;
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
  color: var(--muted);
  font-size: 0.88rem;
}

.status-pill {
  border-radius: 999px;
  padding: 5px 9px;
  font-size: 0.82rem;
  font-weight: 700;
}

.status-passed {
  background: var(--success-bg);
  color: var(--success-text);
}

.status-failed {
  background: var(--danger-bg);
  color: var(--danger-text);
}

.case-body {
  border-top: 1px solid var(--border);
  padding: 14px;
}

.case-body p {
  line-height: 1.5;
  margin-bottom: 12px;
}

.case-meta {
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  margin: 0 0 14px;
}

.case-meta div {
  min-width: 0;
  border-left: 3px solid var(--border);
  padding-left: 9px;
}

.tags span {
  display: inline-block;
  margin: 0 5px 5px 0;
  border-radius: 999px;
  background: var(--surface-muted);
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
  background: #101615;
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

  .library-grid {
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
  const modeFilter = document.getElementById("mode-filter");
  const statusFilter = document.getElementById("status-filter");
  const kindFilter = document.getElementById("kind-filter");

  function applyFilters() {
    const query = (searchInput?.value || "").trim().toLowerCase();
    const mode = modeFilter?.value || "all";
    const status = statusFilter?.value || "all";
    const kind = kindFilter?.value || "all";
    for (const row of rows) {
      const matchesQuery = !query || (row.dataset.search || "").toLowerCase().includes(query);
      const matchesMode = mode === "all" || row.dataset.mode === mode;
      const matchesStatus = status === "all" || row.dataset.status === status;
      const matchesKind = kind === "all" || row.dataset.kind === kind;
      row.hidden = !(matchesQuery && matchesMode && matchesStatus && matchesKind);
    }
  }

  searchInput?.addEventListener("input", applyFilters);
  modeFilter?.addEventListener("change", applyFilters);
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

      this.playButton?.addEventListener("click", () => this.run(() => this.play()));
      this.pauseButton?.addEventListener("click", () => this.pause());
      this.restartButton?.addEventListener("click", () => this.run(() => this.restart()));
      this.scrub?.addEventListener("input", () => this.seekFromScrub());
    }

    showError(error) {
      const message = error instanceof Error ? error.message : String(error);
      this.terminal.textContent = `${message}\n`;
    }

    async run(action) {
      try {
        await action();
      } catch (error) {
        this.pause();
        this.showError(error);
      }
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
      await this.play();
    }
  }

  function playerForRow(row) {
    const playerRoot = row?.querySelector("[data-player]");
    const castHref = row?.dataset.playerCast;
    if (!row || !playerRoot || !castHref) return null;
    if (!playerRoot.castPlayer || playerRoot.castPlayer.castHref !== castHref) {
      playerRoot.castPlayer = new CastPlayer(playerRoot, castHref);
    }
    return playerRoot.castPlayer;
  }

  rows.forEach((row) => playerForRow(row));

  document.querySelectorAll(".js-load-cast").forEach((button) => {
    button.addEventListener("click", async () => {
      const row = button.closest(".case-row");
      const player = playerForRow(row);
      if (!row || !player) return;
      row.open = true;
      await player.run(() => player.restart());
    });
  });
})();
""".strip() + "\n"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", required=True, type=Path)
    parser.add_argument("--tests-root", required=True, type=Path)
    parser.add_argument("--artifact-root", required=True, type=Path)
    parser.add_argument("--proof-path", required=True, action="append", type=Path)
    parser.add_argument("--output-root", required=True, type=Path)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    artifact_root = args.artifact_root.resolve(strict=False)
    output_root = args.output_root.resolve(strict=False)
    proofs = []
    for proof_path in args.proof_path:
        proof_data = load_proof(proof_path, artifact_root=artifact_root)
        validate_proof_matches_artifacts(
            proof_data,
            config_path=args.config,
            tests_root=args.tests_root,
            artifact_root=artifact_root,
        )
        proofs.append(proof_data)

    reset_dir(output_root)
    site_data = build_site_data(
        proofs,
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
    libraries = []
    for proof_data in proofs:
        for library in selected_libraries_from_proof(proof_data):
            if library not in libraries:
                libraries.append(library)
    for library in libraries:
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
