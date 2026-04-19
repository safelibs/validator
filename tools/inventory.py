from __future__ import annotations

import argparse
import sys
from pathlib import Path, PurePosixPath
from typing import Any

import yaml

if __package__ in {None, ""}:
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from tools import ValidatorError


REPO_ROOT = Path(__file__).resolve().parents[1]

LIBRARY_ORDER = (
    "cjson",
    "giflib",
    "libarchive",
    "libbz2",
    "libcsv",
    "libexif",
    "libjpeg-turbo",
    "libjson",
    "liblzma",
    "libpng",
    "libsdl",
    "libsodium",
    "libtiff",
    "libuv",
    "libvips",
    "libwebp",
    "libxml",
    "libyaml",
    "libzstd",
)

CANONICAL_APT_PACKAGES: dict[str, tuple[str, ...]] = {
    "cjson": ("libcjson1", "libcjson-dev"),
    "giflib": ("libgif7", "libgif-dev", "giflib-tools"),
    "libarchive": ("libarchive13t64", "libarchive-dev", "libarchive-tools"),
    "libbz2": ("libbz2-1.0", "libbz2-dev", "bzip2"),
    "libcsv": ("libcsv3", "libcsv-dev"),
    "libexif": ("libexif12", "libexif-dev"),
    "libjpeg-turbo": (
        "libjpeg-turbo8",
        "libjpeg-turbo8-dev",
        "libturbojpeg",
        "libturbojpeg0-dev",
        "libjpeg-turbo-progs",
    ),
    "libjson": ("libjson-c5", "libjson-c-dev"),
    "liblzma": ("liblzma5", "liblzma-dev", "xz-utils"),
    "libpng": ("libpng16-16t64", "libpng-dev", "libpng-tools"),
    "libsdl": ("libsdl2-2.0-0", "libsdl2-dev", "libsdl2-tests"),
    "libsodium": ("libsodium23", "libsodium-dev"),
    "libtiff": ("libtiff6", "libtiffxx6", "libtiff-dev", "libtiff-tools"),
    "libuv": ("libuv1t64", "libuv1-dev"),
    "libvips": ("libvips42t64", "libvips-dev", "libvips-tools", "gir1.2-vips-8.0"),
    "libwebp": (
        "libwebp7",
        "libwebpdemux2",
        "libwebpmux3",
        "libwebpdecoder3",
        "libsharpyuv0",
        "libwebp-dev",
        "libsharpyuv-dev",
        "webp",
    ),
    "libxml": ("libxml2", "libxml2-dev", "libxml2-utils", "python3-libxml2"),
    "libyaml": ("libyaml-0-2", "libyaml-dev"),
    "libzstd": ("libzstd1", "libzstd-dev", "zstd"),
}

ALLOWED_TOP_LEVEL_FIELDS = {"schema_version", "suite", "libraries"}
ALLOWED_SUITE_FIELDS = {"name", "image", "apt_suite"}
ALLOWED_LIBRARY_FIELDS = {"name", "apt_packages", "testcases", "source_snapshot", "fixtures"}
ALLOWED_FIXTURE_FIELDS = {"dependents"}
FORBIDDEN_PACKAGE_FIELDS = {
    "override" + "_packages",
    "verify" + "_packages",
}
FORBIDDEN_SCHEMA_FIELDS = {
    "archive",
    "inventory",
    "repositories",
    "build",
    "github_repo",
    "ref",
    "validator",
    "imports",
    "checkout" + "-artifacts",
    "base_url",
    "pin_priority",
    "artifact_globs",
}
FORBIDDEN_FIXTURE_TERMS = ("cve", "security")
FORBIDDEN_STRING_TERMS = (
    "checkout" + "-artifacts",
)


def load_yaml_mapping(path: Path) -> dict[str, Any]:
    try:
        data = yaml.safe_load(path.read_text())
    except FileNotFoundError as exc:
        raise ValidatorError(f"missing manifest: {path}") from exc
    except yaml.YAMLError as exc:
        raise ValidatorError(f"invalid manifest YAML at {path}: {exc}") from exc
    if not isinstance(data, dict):
        raise ValidatorError(f"{path} must contain a YAML mapping")
    return data


def _require_mapping(value: Any, *, field_name: str, path: Path) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise ValidatorError(f"{field_name} must be a YAML mapping in {path}")
    return value


def _require_non_empty_string(value: Any, *, field_name: str, path: Path) -> str:
    if not isinstance(value, str) or not value.strip():
        raise ValidatorError(f"{field_name} must be a non-empty string in {path}")
    return value.strip()


def _require_string_list(value: Any, *, field_name: str, path: Path) -> list[str]:
    if not isinstance(value, list) or not value:
        raise ValidatorError(f"{field_name} must be a non-empty list in {path}")
    normalized: list[str] = []
    for item in value:
        if not isinstance(item, str) or not item.strip():
            raise ValidatorError(f"{field_name} entries must be non-empty strings in {path}")
        normalized.append(item.strip())
    return normalized


def _reject_unexpected_fields(
    payload: dict[str, Any],
    *,
    allowed: set[str],
    context: str,
) -> None:
    unexpected = sorted(set(payload) - allowed)
    if unexpected:
        raise ValidatorError(f"{context} contains unsupported fields: {', '.join(unexpected)}")


def _reject_forbidden_terms(value: Any, *, context: str) -> None:
    if isinstance(value, dict):
        for key, item in value.items():
            key_text = str(key)
            if key_text in FORBIDDEN_SCHEMA_FIELDS:
                raise ValidatorError(f"{context} contains forbidden schema field: {key_text}")
            if key_text in FORBIDDEN_PACKAGE_FIELDS:
                raise ValidatorError(f"{context} contains forbidden package-list field: {key_text}")
            _reject_forbidden_terms(item, context=f"{context}.{key_text}")
    elif isinstance(value, list):
        for index, item in enumerate(value, start=1):
            _reject_forbidden_terms(item, context=f"{context}[{index}]")
    elif isinstance(value, str):
        for term in FORBIDDEN_STRING_TERMS:
            if term in value:
                raise ValidatorError(f"{context} contains forbidden legacy metadata: {term}")


def _validate_repo_relative_path(value: Any, *, field_name: str, path: Path) -> str:
    text = _require_non_empty_string(value, field_name=field_name, path=path)
    if "\\" in text:
        raise ValidatorError(f"{field_name} must be a repository-relative POSIX path in {path}: {text!r}")
    pure = PurePosixPath(text)
    if pure.is_absolute() or any(part in {"", ".", ".."} for part in pure.parts):
        raise ValidatorError(f"{field_name} must be a repository-relative path in {path}: {text!r}")
    target = (REPO_ROOT / Path(*pure.parts)).resolve(strict=False)
    try:
        target.relative_to(REPO_ROOT.resolve(strict=False))
    except ValueError as exc:
        raise ValidatorError(f"{field_name} must stay within the repository in {path}: {text!r}") from exc
    if not target.exists():
        raise ValidatorError(f"{field_name} path does not exist in {path}: {text}")
    return text


def _validate_suite(suite: Any, *, path: Path) -> None:
    suite_mapping = _require_mapping(suite, field_name="suite", path=path)
    _reject_unexpected_fields(suite_mapping, allowed=ALLOWED_SUITE_FIELDS, context=f"{path} suite")
    _require_non_empty_string(suite_mapping.get("name"), field_name="suite.name", path=path)
    _require_non_empty_string(suite_mapping.get("image"), field_name="suite.image", path=path)
    _require_non_empty_string(suite_mapping.get("apt_suite"), field_name="suite.apt_suite", path=path)


def _validate_fixtures(fixtures: Any, *, library: str, path: Path) -> None:
    fixture_mapping = _require_mapping(fixtures, field_name=f"{library}.fixtures", path=path)
    _reject_unexpected_fields(
        fixture_mapping,
        allowed=ALLOWED_FIXTURE_FIELDS,
        context=f"{path} {library}.fixtures",
    )
    for fixture_name in fixture_mapping:
        normalized = fixture_name.lower()
        if any(term in normalized for term in FORBIDDEN_FIXTURE_TERMS):
            raise ValidatorError(f"{path} {library}.fixtures must not reference CVE or security fixtures")
    dependents_path = _require_non_empty_string(
        fixture_mapping.get("dependents"),
        field_name=f"{library}.fixtures.dependents",
        path=path,
    )
    if any(term in dependents_path.lower() for term in FORBIDDEN_FIXTURE_TERMS):
        raise ValidatorError(f"{path} {library}.fixtures must not reference CVE or security fixtures")
    _validate_repo_relative_path(
        dependents_path,
        field_name=f"{library}.fixtures.dependents",
        path=path,
    )


def _validate_library(entry: Any, *, path: Path, index: int) -> str:
    if not isinstance(entry, dict):
        raise ValidatorError(f"{path} library #{index} must be a YAML mapping")
    _reject_unexpected_fields(
        entry,
        allowed=ALLOWED_LIBRARY_FIELDS,
        context=f"{path} library #{index}",
    )

    name = _require_non_empty_string(entry.get("name"), field_name=f"library #{index}.name", path=path)
    expected_packages = CANONICAL_APT_PACKAGES.get(name)
    if expected_packages is None:
        raise ValidatorError(f"{path} defines unsupported library: {name}")

    apt_packages = _require_string_list(
        entry.get("apt_packages"),
        field_name=f"{name}.apt_packages",
        path=path,
    )
    if tuple(apt_packages) != expected_packages:
        raise ValidatorError(
            f"{path} {name}.apt_packages must equal the canonical ordered package list: "
            f"{list(expected_packages)!r}"
        )

    testcases = _validate_repo_relative_path(entry.get("testcases"), field_name=f"{name}.testcases", path=path)
    expected_testcases = f"tests/{name}/testcases.yml"
    if testcases != expected_testcases:
        raise ValidatorError(f"{path} {name}.testcases must be {expected_testcases!r}")

    _validate_repo_relative_path(
        entry.get("source_snapshot"),
        field_name=f"{name}.source_snapshot",
        path=path,
    )
    _validate_fixtures(entry.get("fixtures"), library=name, path=path)
    return name


def load_manifest(
    path: Path,
    *,
    require_inventory: bool | None = None,
    require_validator: bool | None = None,
) -> dict[str, Any]:
    del require_inventory, require_validator

    data = load_yaml_mapping(path)
    _reject_forbidden_terms(data, context=str(path))
    _reject_unexpected_fields(data, allowed=ALLOWED_TOP_LEVEL_FIELDS, context=str(path))

    if data.get("schema_version") != 2:
        raise ValidatorError(f"{path} schema_version must be 2")
    _validate_suite(data.get("suite"), path=path)

    libraries = data.get("libraries")
    if not isinstance(libraries, list) or not libraries:
        raise ValidatorError(f"{path} must define a non-empty libraries list")

    names = [_validate_library(entry, path=path, index=index) for index, entry in enumerate(libraries, start=1)]
    duplicates = sorted({name for name in names if names.count(name) > 1})
    if duplicates:
        raise ValidatorError(f"{path} defines duplicate libraries: {', '.join(duplicates)}")
    if tuple(names) != LIBRARY_ORDER:
        raise ValidatorError(f"{path} libraries must appear in the fixed v2 order: {list(LIBRARY_ORDER)!r}")
    return data


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", required=True, type=Path)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    load_manifest(args.config)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ValidatorError as exc:
        print(str(exc), file=sys.stderr)
        raise SystemExit(1)
