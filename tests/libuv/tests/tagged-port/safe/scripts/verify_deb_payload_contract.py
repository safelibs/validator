#!/usr/bin/env python3

import argparse
import filecmp
import fnmatch
import os
import subprocess
import sys
import tempfile
from pathlib import Path


def fail(message: str) -> "NoReturn":
    print(message, file=sys.stderr)
    raise SystemExit(1)


def load_artifacts_env(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if "=" not in line:
            fail(f"invalid artifacts.env line: {raw_line}")
        key, value = line.split("=", 1)
        values[key] = value
    return values


def package_field(deb_path: Path, field: str) -> str:
    return subprocess.check_output(
        ["dpkg-deb", "-f", str(deb_path), field],
        text=True,
    ).strip()


def multiarch_triplet() -> str:
    return subprocess.check_output(
        ["dpkg-architecture", "-qDEB_HOST_MULTIARCH"],
        text=True,
    ).strip()


def unpack(deb_path: Path, destination: Path) -> None:
    subprocess.run(["dpkg-deb", "-x", str(deb_path), str(destination)], check=True)


def collect_payload(root: Path) -> dict[str, tuple[str, str | None]]:
    payload: dict[str, tuple[str, str | None]] = {}
    for path in sorted(root.rglob("*")):
        if path.is_dir():
            continue
        relpath = path.relative_to(root).as_posix()
        if path.is_symlink():
            payload[relpath] = ("symlink", os.readlink(path))
        elif path.is_file():
            payload[relpath] = ("file", None)
        else:
            fail(f"unsupported payload entry type: {path}")
    return payload


def expected_runtime_payload(multiarch: str) -> dict[str, tuple[str, str | None]]:
    return {
        f"usr/lib/{multiarch}/libuv.so.1": ("symlink", "libuv.so.1.0.0"),
        f"usr/lib/{multiarch}/libuv.so.1.0.0": ("file", None),
        "usr/share/doc/libuv1t64/changelog.Debian.gz": ("file", None),
        "usr/share/doc/libuv1t64/copyright": ("file", None),
    }


def expected_dev_payload(multiarch: str, original_include: Path) -> dict[str, tuple[str, str | None]]:
    payload = {
        f"usr/lib/{multiarch}/libuv.a": ("file", None),
        f"usr/lib/{multiarch}/libuv.so": ("symlink", "libuv.so.1"),
        f"usr/lib/{multiarch}/pkgconfig/libuv.pc": ("file", None),
        f"usr/lib/{multiarch}/pkgconfig/libuv-static.pc": ("file", None),
        "usr/share/doc/libuv1-dev/changelog.Debian.gz": ("file", None),
        "usr/share/doc/libuv1-dev/copyright": ("file", None),
    }

    for header in sorted(path for path in original_include.rglob("*") if path.is_file()):
        relpath = header.relative_to(original_include).as_posix()
        payload[f"usr/include/{relpath}"] = ("file", None)

    return payload


def assert_exact_payload(
    actual: dict[str, tuple[str, str | None]],
    expected: dict[str, tuple[str, str | None]],
    package_name: str,
) -> None:
    actual_paths = set(actual)
    expected_paths = set(expected)
    if actual_paths != expected_paths:
        missing = sorted(expected_paths - actual_paths)
        extra = sorted(actual_paths - expected_paths)
        problems = []
        if missing:
            problems.append("missing: " + ", ".join(missing))
        if extra:
            problems.append("extra: " + ", ".join(extra))
        fail(f"{package_name}: unexpected payload entries ({'; '.join(problems)})")

    for relpath, expected_entry in expected.items():
        actual_entry = actual[relpath]
        if actual_entry != expected_entry:
            fail(f"{package_name}: payload entry mismatch for {relpath}: {actual_entry} != {expected_entry}")


def assert_header_bytes_match(dev_root: Path, original_include: Path) -> None:
    packaged_include = dev_root / "usr" / "include"
    if not packaged_include.is_dir():
        fail(f"missing packaged include tree: {packaged_include}")

    original_headers = sorted(path for path in original_include.rglob("*") if path.is_file())
    packaged_headers = sorted(path for path in packaged_include.rglob("*") if path.is_file())

    original_rel = [path.relative_to(original_include).as_posix() for path in original_headers]
    packaged_rel = [path.relative_to(packaged_include).as_posix() for path in packaged_headers]
    if original_rel != packaged_rel:
        fail("packaged public header set differs from original/include")

    for original_header in original_headers:
        relpath = original_header.relative_to(original_include)
        packaged_header = packaged_include / relpath
        if not filecmp.cmp(original_header, packaged_header, shallow=False):
            fail(f"packaged header differs from original/include: {relpath.as_posix()}")


def normalize_not_installed_patterns(path: Path) -> list[str]:
    patterns: list[str] = []
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        while line.startswith("./"):
            line = line[2:]
        if line.startswith("debian/tmp/"):
            line = line[len("debian/tmp/") :]
        patterns.append(line)
    if not patterns:
        fail(f"no patterns found in not-installed file: {path}")
    return patterns


def assert_not_installed(patterns: list[str], packaged_paths: set[str]) -> None:
    for relpath in sorted(packaged_paths):
        matches = [pattern for pattern in patterns if fnmatch.fnmatch(relpath, pattern)]
        if matches:
            fail(
                f"packaged path {relpath} unexpectedly matches debian/not-installed pattern(s): "
                + ", ".join(matches)
            )


def main() -> int:
    parser = argparse.ArgumentParser(
        prog="verify_deb_payload_contract.py",
        description="Verify exact libuv Debian package payloads and packaged public headers."
    )
    parser.add_argument("artifacts_env", help="safe/dist/artifacts.env")
    parser.add_argument("original_include", help="original/include directory")
    parser.add_argument("not_installed", help="safe/debian/not-installed")
    args = parser.parse_args()

    artifacts_env = Path(args.artifacts_env).resolve()
    original_include = Path(args.original_include).resolve()
    not_installed = Path(args.not_installed).resolve()

    if not artifacts_env.is_file():
        fail(f"missing artifacts env: {artifacts_env}")
    if not original_include.is_dir():
        fail(f"missing original include tree: {original_include}")
    if not not_installed.is_file():
        fail(f"missing not-installed file: {not_installed}")

    env = load_artifacts_env(artifacts_env)
    try:
        runtime_deb = Path(env["LIBUV_SAFE_RUNTIME_DEB"]).resolve()
        dev_deb = Path(env["LIBUV_SAFE_DEV_DEB"]).resolve()
    except KeyError as exc:
        fail(f"artifacts.env missing required key: {exc.args[0]}")

    if not runtime_deb.is_file():
        fail(f"missing runtime deb: {runtime_deb}")
    if not dev_deb.is_file():
        fail(f"missing dev deb: {dev_deb}")

    if package_field(runtime_deb, "Package") != "libuv1t64":
        fail(f"unexpected runtime package name: {runtime_deb}")
    if package_field(dev_deb, "Package") != "libuv1-dev":
        fail(f"unexpected development package name: {dev_deb}")

    multiarch = multiarch_triplet()
    runtime_expected = expected_runtime_payload(multiarch)
    dev_expected = expected_dev_payload(multiarch, original_include)
    not_installed_patterns = normalize_not_installed_patterns(not_installed)

    with tempfile.TemporaryDirectory(prefix="libuv-deb-verify-") as temp_root_name:
        temp_root = Path(temp_root_name)
        runtime_root = temp_root / "runtime"
        dev_root = temp_root / "dev"
        runtime_root.mkdir()
        dev_root.mkdir()

        unpack(runtime_deb, runtime_root)
        unpack(dev_deb, dev_root)

        runtime_actual = collect_payload(runtime_root)
        dev_actual = collect_payload(dev_root)

        assert_exact_payload(runtime_actual, runtime_expected, "libuv1t64")
        assert_exact_payload(dev_actual, dev_expected, "libuv1-dev")
        assert_header_bytes_match(dev_root, original_include)
        assert_not_installed(
            not_installed_patterns,
            set(runtime_actual) | set(dev_actual),
        )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
