from __future__ import annotations

import argparse
import copy
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable

import yaml

if __package__ in {None, ""}:
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from tools import ValidatorError, redact_secrets, write_json
from tools import github_auth


GH_REPO_LIST_COMMAND = (
    "gh repo list safelibs --limit 200 --json name,nameWithOwner,isPrivate,url,defaultBranchRef"
)
TAG_PROBE_RULE = "refs/tags/{library}/04-test"
GOAL_REPO_FAMILY = "repos-*"
VERIFIED_REPO_FAMILY = "port-*"
NON_APT_LIBRARIES = {"libexif", "libuv"}
FILTERED_ROW_KEYS = {"library", "nameWithOwner", "url", "default_branch", "tag_ref"}
REQUIRED_INVENTORY_KEYS = {
    "verified_at",
    "gh_repo_list_command",
    "tag_probe_rule",
    "raw_snapshot",
    "filtered_snapshot",
    "goal_repo_family",
    "verified_repo_family",
}
VALIDATOR_IMPORTS = {
    "cjson": [
        "safe/tests",
        "safe/scripts",
        "original/tests",
        "original/fuzzing",
        "original/test.c",
        "original/cJSON.h",
        "original/cJSON_Utils.h",
    ],
    "giflib": [
        "safe/tests",
        "original/tests",
        "original/pic",
        "original/gif_lib.h",
    ],
    "libarchive": [
        "safe/tests",
        "safe/debian/tests",
        "safe/scripts",
        "safe/generated/api_inventory.json",
        "safe/generated/cve_matrix.json",
        "safe/generated/link_compat_manifest.json",
        "safe/generated/original_build_contract.json",
        "safe/generated/original_package_metadata.json",
        "safe/generated/original_c_build",
        "safe/generated/original_link_objects",
        "safe/generated/original_pkgconfig/libarchive.pc",
        "safe/generated/pkgconfig/libarchive.pc",
        "safe/generated/rust_test_manifest.json",
        "safe/generated/test_manifest.json",
        "original/libarchive-3.7.2",
    ],
    "libbz2": [
        "safe/tests",
        "safe/debian/tests",
        "safe/scripts",
        "original",
    ],
    "libcsv": [
        "safe/tests",
        "safe/debian/tests",
        "original/examples",
        "original/test_csv.c",
        "original/csv.h",
    ],
    "libexif": [
        "safe/tests",
        "original/libexif",
        "original/test",
        "original/contrib/examples",
    ],
    "libjpeg-turbo": [
        "safe/tests",
        "safe/debian/tests",
        "safe/scripts",
        "original/testimages",
    ],
    "libjson": [
        "safe/tests",
        "safe/debian/tests",
    ],
    "liblzma": [
        "safe/docker",
        "safe/scripts",
        "safe/tests/dependents",
        "safe/tests/extra",
        "safe/tests/upstream",
    ],
    "libpng": [
        "safe/tests",
        "original/tests",
        "original/contrib/pngsuite",
        "original/contrib/testpngs",
        "original/png.h",
        "original/pngconf.h",
        "original/pngtest.png",
    ],
    "libsdl": [
        "safe/tests",
        "safe/debian/tests",
        "safe/generated/dependent_regression_manifest.json",
        "safe/generated/noninteractive_test_list.json",
        "safe/generated/original_test_port_map.json",
        "safe/generated/perf_workload_manifest.json",
        "safe/generated/perf_thresholds.json",
        "safe/generated/reports/perf-baseline-vs-safe.json",
        "safe/generated/reports/perf-waivers.md",
        "safe/upstream-tests",
        "original/test",
    ],
    "libsodium": [
        "safe/tests",
        "safe/docker",
    ],
    "libtiff": [
        "safe/test",
        "safe/scripts",
        "original/test",
    ],
    "libuv": [
        "safe/docker",
        "safe/include",
        "safe/prebuilt",
        "safe/scripts",
        "safe/test",
        "safe/test-extra",
    ],
    "libvips": [
        "safe/tests/dependents",
        "safe/tests/upstream",
        "safe/vendor/pyvips-3.1.1",
        "original/test",
        "original/examples",
    ],
    "libwebp": [
        "safe/tests",
        "original/examples",
        "original/tests/public_api_test.c",
    ],
    "libxml": [
        "safe/tests",
        "safe/debian/tests",
        "safe/scripts",
        "original",
    ],
    "libyaml": [
        "safe/tests",
        "safe/debian/tests",
        "safe/scripts",
        "original/include",
        "original/tests",
        "original/examples",
    ],
    "libzstd": [
        "safe/tests",
        "safe/debian/tests",
        "safe/docker",
        "safe/scripts",
        "original/libzstd-1.5.5+dfsg2",
    ],
}


def iso_utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def load_yaml_mapping(path: Path) -> dict[str, Any]:
    data = yaml.safe_load(path.read_text())
    if not isinstance(data, dict):
        raise ValidatorError(f"{path} must contain a YAML mapping")
    return data


def load_manifest(
    path: Path,
    *,
    require_inventory: bool = True,
    require_validator: bool = True,
) -> dict[str, Any]:
    data = load_yaml_mapping(path)
    archive = data.get("archive")
    repositories = data.get("repositories")
    if not isinstance(archive, dict):
        raise ValidatorError(f"{path} must define archive")
    if not isinstance(repositories, list) or not repositories:
        raise ValidatorError(f"{path} must define a non-empty repositories list")

    inventory = data.get("inventory")
    if require_inventory and not isinstance(inventory, dict):
        raise ValidatorError(f"{path} must define inventory")

    names: set[str] = set()
    for index, entry in enumerate(repositories, start=1):
        if not isinstance(entry, dict):
            raise ValidatorError(f"{path} repository #{index} must be a YAML mapping")
        for field in ("name", "github_repo", "ref"):
            if not str(entry.get(field) or "").strip():
                raise ValidatorError(f"{path} repository #{index} must define {field}")
        name = str(entry["name"])
        if name in names:
            raise ValidatorError(f"{path} defines duplicate repository name: {name}")
        names.add(name)

        build = entry.get("build")
        if not isinstance(build, dict):
            raise ValidatorError(f"{path} repository #{index} must define build")
        artifact_globs = build.get("artifact_globs")
        if not isinstance(artifact_globs, list) or not artifact_globs:
            raise ValidatorError(
                f"{path} repository #{index} build must define artifact_globs"
            )

        if require_validator:
            validator = entry.get("validator")
            fixtures = entry.get("fixtures")
            if not isinstance(validator, dict):
                raise ValidatorError(f"{path} repository #{index} must define validator")
            if not isinstance(fixtures, dict):
                raise ValidatorError(f"{path} repository #{index} must define fixtures")
            imports = validator.get("imports")
            if not isinstance(imports, list) or not imports:
                raise ValidatorError(
                    f"{path} repository #{index} validator.imports must be a non-empty list"
                )
            if validator.get("import_excludes") != []:
                raise ValidatorError(
                    f"{path} repository #{index} validator.import_excludes must be []"
                )
            sibling_repo = str(validator.get("sibling_repo") or "").strip()
            if not sibling_repo:
                raise ValidatorError(
                    f"{path} repository #{index} validator.sibling_repo must be set"
                )
            for fixture_name in ("dependents", "relevant_cves"):
                fixture = fixtures.get(fixture_name)
                if not isinstance(fixture, dict) or fixture.get("source") != "copy-staged-root":
                    raise ValidatorError(
                        f"{path} repository #{index} fixtures.{fixture_name}.source mismatch"
                    )
    return data


def load_github_inventory(path: Path) -> list[dict[str, Any]]:
    data = json.loads(path.read_text())
    if not isinstance(data, list):
        raise ValidatorError(f"{path} must contain a JSON array")
    for index, row in enumerate(data, start=1):
        if not isinstance(row, dict):
            raise ValidatorError(f"{path} row #{index} must be a JSON object")
    return data


def remote_tag_reachable(github_repo: str, tag_ref: str) -> bool:
    command = [
        "git",
        "ls-remote",
        "--exit-code",
        github_auth.github_git_url(github_repo),
        tag_ref,
    ]
    completed = subprocess.run(
        command,
        env=github_auth.git_env(),
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode == 0:
        return bool(completed.stdout.strip())
    if completed.returncode == 2:
        return False

    raise ValidatorError(
        f"unable to probe {github_repo} {tag_ref}: "
        f"{redact_secrets(completed.stderr.strip() or str(completed.returncode))}"
    )


def supported_library_names(apt_manifest: dict[str, Any]) -> set[str]:
    return {str(entry["name"]) for entry in apt_manifest["repositories"]} | set(NON_APT_LIBRARIES)


def validator_imports_for(library: str) -> list[str]:
    imports = VALIDATOR_IMPORTS.get(library)
    if imports is None:
        raise ValidatorError(f"missing validator imports for supported library {library}")
    return list(imports)


def select_tagged_scope(
    github_rows: list[dict[str, Any]],
    *,
    supported_libraries: set[str],
    probe: Callable[[str, str], bool] = remote_tag_reachable,
    tag_probe_rule: str = TAG_PROBE_RULE,
) -> list[dict[str, Any]]:
    selected: list[dict[str, Any]] = []
    for row in github_rows:
        name = str(row.get("name") or "")
        if not name.startswith("port-"):
            continue
        library = name.removeprefix("port-")
        if library not in supported_libraries:
            continue
        tag_ref = tag_probe_rule.format(library=library)
        github_repo = str(row.get("nameWithOwner") or "")
        if not github_repo:
            raise ValidatorError(f"raw GitHub row missing nameWithOwner for {name}")
        if not probe(github_repo, tag_ref):
            continue
        selected.append(
            {
                "library": library,
                "nameWithOwner": github_repo,
                "url": str(row.get("url") or ""),
                "default_branch": (row.get("defaultBranchRef") or {}).get("name"),
                "tag_ref": tag_ref,
            }
        )
    return sorted(selected, key=lambda item: item["library"])


def merge_apt_repo_metadata(
    apt_manifest: dict[str, Any],
    filtered_rows: list[dict[str, Any]],
    *,
    verified_at: str | None = None,
    raw_snapshot: str = "inventory/github-repo-list.json",
    filtered_snapshot: str = "inventory/github-port-repos.json",
) -> dict[str, Any]:
    apt_entries = {entry["name"]: entry for entry in apt_manifest["repositories"]}
    repositories: list[dict[str, Any]] = []
    for row in filtered_rows:
        library = row["library"]
        tag_ref = row["tag_ref"]
        github_repo = str(row["nameWithOwner"])
        if library in apt_entries:
            apt_entry = apt_entries[library]
            repository: dict[str, Any] = {
                "name": library,
                "github_repo": copy.deepcopy(apt_entry["github_repo"]),
                "ref": tag_ref,
            }
            if "verify_packages" in apt_entry:
                repository["verify_packages"] = copy.deepcopy(apt_entry["verify_packages"])
            repository["build"] = copy.deepcopy(apt_entry["build"])
        elif library in NON_APT_LIBRARIES:
            repository = {
                "name": library,
                "github_repo": github_repo,
                "ref": tag_ref,
                "build": {
                    "mode": "safe-debian",
                    "artifact_globs": ["*.deb"],
                },
            }
        else:
            raise ValidatorError(f"filtered library {library} is not present in apt-repo metadata")

        repository["validator"] = {
            "sibling_repo": f"port-{library}",
            "imports": validator_imports_for(library),
            "import_excludes": [],
        }
        repository["fixtures"] = {
            "dependents": {"source": "copy-staged-root"},
            "relevant_cves": {"source": "copy-staged-root"},
        }
        repositories.append(repository)

    return {
        "archive": copy.deepcopy(apt_manifest["archive"]),
        "inventory": {
            "verified_at": verified_at or iso_utc_now(),
            "gh_repo_list_command": GH_REPO_LIST_COMMAND,
            "tag_probe_rule": TAG_PROBE_RULE,
            "raw_snapshot": raw_snapshot,
            "filtered_snapshot": filtered_snapshot,
            "goal_repo_family": GOAL_REPO_FAMILY,
            "verified_repo_family": VERIFIED_REPO_FAMILY,
        },
        "repositories": repositories,
    }


def validate_filtered_rows(filtered_rows: list[dict[str, Any]]) -> None:
    libraries = [row["library"] for row in filtered_rows]
    if libraries != sorted(libraries):
        raise ValidatorError(f"filtered inventory must be sorted by library: {libraries}")
    for row in filtered_rows:
        if set(row) != FILTERED_ROW_KEYS:
            raise ValidatorError(
                f"filtered inventory row schema mismatch for {row.get('library', '<unknown>')}: {sorted(row)}"
            )


def validate_inventory_metadata(inventory: dict[str, Any]) -> None:
    if set(REQUIRED_INVENTORY_KEYS) - set(inventory):
        missing = sorted(set(REQUIRED_INVENTORY_KEYS) - set(inventory))
        raise ValidatorError(f"inventory metadata is incomplete: {', '.join(missing)}")
    expected = {
        "gh_repo_list_command": GH_REPO_LIST_COMMAND,
        "tag_probe_rule": TAG_PROBE_RULE,
        "raw_snapshot": "inventory/github-repo-list.json",
        "filtered_snapshot": "inventory/github-port-repos.json",
        "goal_repo_family": GOAL_REPO_FAMILY,
        "verified_repo_family": VERIFIED_REPO_FAMILY,
    }
    for key, expected_value in expected.items():
        if inventory.get(key) != expected_value:
            raise ValidatorError(f"inventory {key} mismatch: {inventory.get(key)!r}")
    if not str(inventory.get("verified_at") or "").strip():
        raise ValidatorError("inventory verified_at must be set")


def verify_scope(
    github_rows: list[dict[str, Any]],
    filtered_rows: list[dict[str, Any]],
    manifest: dict[str, Any],
    *,
    supported_libraries: set[str],
    probe: Callable[[str, str], bool] = remote_tag_reachable,
) -> None:
    validate_filtered_rows(filtered_rows)
    validate_inventory_metadata(manifest["inventory"])
    tag_probe_rule = manifest["inventory"]["tag_probe_rule"]
    expected_filtered = select_tagged_scope(
        github_rows,
        supported_libraries=supported_libraries,
        probe=probe,
        tag_probe_rule=tag_probe_rule,
    )
    if filtered_rows != expected_filtered:
        raise ValidatorError("filtered inventory diverges from the live tagged subset")

    manifest_names = [entry["name"] for entry in manifest["repositories"]]
    filtered_names = [row["library"] for row in filtered_rows]
    if manifest_names != filtered_names:
        raise ValidatorError("manifest repositories diverge from filtered inventory order")

    filtered_by_library = {row["library"]: row for row in filtered_rows}
    for entry in manifest["repositories"]:
        expected_row = filtered_by_library[entry["name"]]
        if entry.get("github_repo") != expected_row["nameWithOwner"]:
            raise ValidatorError(
                f"{entry['name']} github_repo mismatch: {entry.get('github_repo')!r}"
            )
        expected_ref = tag_probe_rule.format(library=entry["name"])
        if entry.get("ref") != expected_ref:
            raise ValidatorError(f"{entry['name']} ref mismatch: {entry.get('ref')!r}")


def write_manifest(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(yaml.safe_dump(data, sort_keys=False))


def generate_inventory(
    github_json: Path,
    apt_config: Path,
    write_filtered: Path,
    write_config: Path,
    *,
    verify_generated_scope: bool,
) -> None:
    github_rows = load_github_inventory(github_json)
    apt_manifest = load_manifest(apt_config, require_inventory=False, require_validator=False)
    supported_libraries = supported_library_names(apt_manifest)
    filtered_rows = select_tagged_scope(github_rows, supported_libraries=supported_libraries)
    manifest = merge_apt_repo_metadata(apt_manifest, filtered_rows)
    if verify_generated_scope:
        verify_scope(
            github_rows,
            filtered_rows,
            manifest,
            supported_libraries=supported_libraries,
        )
    write_json(write_filtered, filtered_rows)
    write_manifest(write_config, manifest)


def check_remote_tags(config: Path) -> None:
    manifest = load_manifest(config)
    tag_probe_rule = manifest["inventory"]["tag_probe_rule"]
    failures: list[str] = []
    for entry in manifest["repositories"]:
        library = entry["name"]
        expected_ref = tag_probe_rule.format(library=library)
        if entry["ref"] != expected_ref:
            failures.append(f"{library} ref mismatch: {entry['ref']!r}")
            continue
        if not remote_tag_reachable(entry["github_repo"], expected_ref):
            failures.append(f"{library} missing remote tag: {expected_ref}")
    if failures:
        raise ValidatorError("\n".join(failures))


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    parser.add_argument("--github-json", type=Path)
    parser.add_argument("--apt-config", type=Path)
    parser.add_argument("--write-filtered", type=Path)
    parser.add_argument("--write-config", type=Path)
    parser.add_argument("--verify-scope", action="store_true")
    parser.add_argument("--config", type=Path)
    parser.add_argument("--check-remote-tags", action="store_true")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    if args.check_remote_tags:
        if args.config is None:
            raise ValidatorError("--config is required with --check-remote-tags")
        check_remote_tags(args.config)
        return 0

    required = [
        ("--github-json", args.github_json),
        ("--apt-config", args.apt_config),
        ("--write-filtered", args.write_filtered),
        ("--write-config", args.write_config),
    ]
    missing = [flag for flag, value in required if value is None]
    if missing:
        raise ValidatorError(f"missing required arguments: {', '.join(missing)}")
    generate_inventory(
        args.github_json,
        args.apt_config,
        args.write_filtered,
        args.write_config,
        verify_generated_scope=args.verify_scope,
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ValidatorError as exc:
        print(str(exc), file=sys.stderr)
        raise SystemExit(1)
