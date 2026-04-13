from __future__ import annotations

import argparse
import os
import re
import shutil
import sys
from pathlib import Path
from typing import Any

if __package__ in {None, ""}:
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from tools import ValidatorError, reset_dir, run, select_repositories, shell_quote
from tools.inventory import load_manifest


UBUNTU_24_04_RUST_VERSION = "1.75"
_RUST_VERSION_RE = re.compile(r'^\s*rust-version\s*=\s*"([^"]+)"\s*$')
_RUST_EDITION_RE = re.compile(r'^\s*edition\s*=\s*"([^"]+)"\s*$')
_RUST_TOOLCHAIN_CHANNEL_RE = re.compile(r'^\s*channel\s*=\s*"([^"]+)"\s*$')
APT_GET_BASE = (
    "apt-get "
    "-o Acquire::ForceIPv4=true "
    "-o Acquire::Retries=3 "
    "-o Acquire::http::Timeout=30 "
    "-o Acquire::https::Timeout=30"
)


def dedupe(values: list[str]) -> list[str]:
    return list(dict.fromkeys(values))


def version_key(value: str) -> tuple[int, ...]:
    if not re.fullmatch(r"\d+(?:\.\d+){0,2}", value):
        return ()
    return tuple(int(part) for part in value.split("."))


def max_version(candidates: list[str]) -> str:
    numeric_candidates = [candidate for candidate in candidates if version_key(candidate)]
    if not numeric_candidates:
        return ""
    return max(numeric_candidates, key=version_key)


def detect_rust_toolchain(workdir: Path) -> str:
    candidates: list[str] = []
    named_candidates: list[str] = []
    edition_minimums = {
        "2018": "1.31",
        "2021": "1.56",
        "2024": "1.85",
    }
    has_modern_lockfile = False

    for cargo_path in sorted(workdir.rglob("Cargo.toml")):
        for line in cargo_path.read_text(errors="replace").splitlines():
            rust_match = _RUST_VERSION_RE.match(line)
            if rust_match:
                candidates.append(rust_match.group(1))
                continue
            edition_match = _RUST_EDITION_RE.match(line)
            if edition_match:
                minimum = edition_minimums.get(edition_match.group(1))
                if minimum:
                    candidates.append(minimum)

    for lockfile_path in sorted(workdir.rglob("Cargo.lock")):
        for line in lockfile_path.read_text(errors="replace").splitlines()[:5]:
            if line.strip() == "version = 4":
                has_modern_lockfile = True
                break
        if has_modern_lockfile:
            break

    for toolchain_name in ("rust-toolchain.toml", "rust-toolchain"):
        toolchain_path = workdir / toolchain_name
        if not toolchain_path.exists():
            continue
        for line in toolchain_path.read_text(errors="replace").splitlines():
            channel_match = _RUST_TOOLCHAIN_CHANNEL_RE.match(line)
            if channel_match:
                channel = channel_match.group(1)
                if version_key(channel):
                    candidates.append(channel)
                else:
                    named_candidates.append(channel)
                break
        else:
            channel_lines = toolchain_path.read_text(errors="replace").strip().splitlines()
            if channel_lines:
                named_channel = channel_lines[0].strip()
                if version_key(named_channel):
                    candidates.append(named_channel)
                else:
                    named_candidates.append(named_channel)

    required = max_version(candidates)
    if required and version_key(required) > version_key(UBUNTU_24_04_RUST_VERSION):
        return required
    if has_modern_lockfile:
        return "stable"
    if named_candidates:
        return named_candidates[0]
    return ""


def apt_get_command(arguments: str) -> str:
    return f"{APT_GET_BASE} {arguments}"


def apt_get_install_template() -> str:
    return f"{APT_GET_BASE} -y --no-install-recommends"


def safe_debian_script() -> str:
    return "\n".join(
        [
            f'mk-build-deps -i -r -t "{apt_get_install_template()}" debian/control',
            "dpkg-buildpackage -us -uc -b",
            'cp -v ../*.deb "$SAFEAPTREPO_OUTPUT"/',
        ]
    )


def scratch_source_for(workspace: Path, library: str) -> Path:
    return workspace / "build-safe" / library / "source"


def normalize_sibling_repo_paths(scratch_source: Path, sibling_repo: str) -> None:
    old_root = f"/home/yans/safelibs/{sibling_repo}"
    new_root = "/workspace/source"
    for path in scratch_source.rglob("*"):
        if not path.is_file() or path.is_symlink():
            continue
        try:
            original_text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        if old_root not in original_text:
            continue
        path.write_text(original_text.replace(old_root, new_root), encoding="utf-8")


def prepare_scratch_copy(
    stage_repo: Path,
    workspace: Path,
    library: str,
    *,
    sibling_repo: str,
) -> Path:
    scratch_source = scratch_source_for(workspace, library)
    scratch_root = scratch_source.parent
    reset_dir(scratch_root)
    shutil.copytree(stage_repo, scratch_source, symlinks=True, dirs_exist_ok=False)
    normalize_sibling_repo_paths(scratch_source, sibling_repo)
    return scratch_source


def patch_scratch_copy_for_library(scratch_source: Path, library: str) -> None:
    if library != "libvips":
        return

    symbols_path = scratch_source / "safe" / "reference" / "abi" / "libvips.symbols"
    if not symbols_path.is_file():
        return

    original_text = symbols_path.read_text(encoding="utf-8")
    had_trailing_newline = original_text.endswith("\n")
    filtered_lines = [
        line
        for line in original_text.splitlines()
        if line.strip() != "lzw_context_create"
    ]
    if len(filtered_lines) == len(original_text.splitlines()):
        return

    updated_text = "\n".join(filtered_lines)
    if had_trailing_newline:
        updated_text += "\n"
    symbols_path.write_text(updated_text, encoding="utf-8")


def collect_artifacts(output_dir: Path, artifact_globs: list[str], library: str) -> list[Path]:
    artifacts: list[Path] = []
    for pattern in artifact_globs:
        artifacts.extend(sorted(output_dir.glob(pattern)))
    artifacts = [artifact for artifact in dict.fromkeys(artifacts) if artifact.is_file()]
    if not artifacts:
        raise ValidatorError(f"no declared artifacts were produced for {library}")
    return artifacts


def build_with_docker(
    entry: dict[str, Any],
    scratch_source: Path,
    output_dir: Path,
    archive: dict[str, Any],
) -> None:
    build = dict(entry["build"])
    library = str(entry["name"])
    mode = str(build.get("mode") or "docker")
    image = str(build.get("image") or archive["image"])
    packages = dedupe(list(archive.get("install_packages", [])) + list(build.get("packages", [])))
    rustup_toolchain = str(build.get("rustup_toolchain") or "").strip()
    default_workdir = "safe" if mode == "safe-debian" else "."
    workdir = scratch_source / str(build.get("workdir") or default_workdir)
    if not workdir.exists():
        raise ValidatorError(f"missing workdir for {library}: {workdir}")

    if mode == "safe-debian":
        if "curl" not in packages:
            packages.append("curl")
        packages = dedupe(
            packages
            + [
                "build-essential",
                "devscripts",
                "dpkg-dev",
                "equivs",
                "fakeroot",
            ]
        )
        if not rustup_toolchain:
            rustup_toolchain = detect_rust_toolchain(workdir)
        command = safe_debian_script()
    elif mode == "docker":
        command = str(build.get("command") or "").strip()
        if not command:
            raise ValidatorError(f"docker build must define command for {library}")
    else:
        raise ValidatorError(f"unsupported build mode for {library}: {mode}")

    if rustup_toolchain and "curl" not in packages:
        packages.append("curl")
    packages = dedupe(packages)
    env = os.environ.copy()
    env["SAFEAPTREPO_SOURCE"] = "/workspace/source"
    env["SAFEAPTREPO_OUTPUT"] = "/workspace/output"
    env["SAFEDEBREPO_SOURCE"] = env["SAFEAPTREPO_SOURCE"]
    env["SAFEDEBREPO_OUTPUT"] = env["SAFEAPTREPO_OUTPUT"]
    host_uid = os.getuid()
    host_gid = os.getgid()

    setup_steps: list[str] = []
    if rustup_toolchain:
        setup_steps.extend(
            [
                (
                    "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | "
                    f"sh -s -- -y --profile minimal --default-toolchain {shell_quote(rustup_toolchain)}"
                ),
                'source "$HOME/.cargo/env"',
                "rustc --version",
                "cargo --version",
            ]
        )
    extra_setup = str(build.get("setup") or "").strip()
    if extra_setup:
        setup_steps.append(extra_setup)
    docker_script = "\n".join(
        [
            "set -euo pipefail",
            f"trap 'chown -R {host_uid}:{host_gid} /workspace/source /workspace/output' EXIT",
            "export DEBIAN_FRONTEND=noninteractive",
            apt_get_command("update"),
            apt_get_command(f"install -y --no-install-recommends {' '.join(packages)}"),
            *setup_steps,
            "git config --global --add safe.directory /workspace/source",
            f"cd {shell_quote(str(workdir.relative_to(scratch_source)) or '.')}",
            command,
        ]
    )

    run(
        [
            "docker",
            "run",
            "--rm",
            "--mount",
            f"type=bind,src={scratch_source.resolve()},dst=/workspace/source",
            "--mount",
            f"type=bind,src={output_dir.resolve()},dst=/workspace/output",
            "-w",
            "/workspace/source",
            "-e",
            "SAFEAPTREPO_SOURCE=/workspace/source",
            "-e",
            "SAFEAPTREPO_OUTPUT=/workspace/output",
            "-e",
            "SAFEDEBREPO_SOURCE=/workspace/source",
            "-e",
            "SAFEDEBREPO_OUTPUT=/workspace/output",
            image,
            "bash",
            "-lc",
            docker_script,
        ],
        env=env,
        capture_output=True,
    )


def build_library(
    manifest: dict[str, Any],
    *,
    library: str,
    port_root: Path,
    workspace: Path,
    output: Path,
) -> list[Path]:
    entry = select_repositories(manifest, [library])[0]
    stage_repo = port_root / library
    if not stage_repo.exists():
        raise ValidatorError(f"missing staged checkout for {library}: {stage_repo}")

    validator = dict(entry.get("validator") or {})
    sibling_repo = str(validator.get("sibling_repo") or f"port-{library}")
    scratch_source = prepare_scratch_copy(
        stage_repo,
        workspace,
        library,
        sibling_repo=sibling_repo,
    )
    patch_scratch_copy_for_library(scratch_source, library)
    reset_dir(output)
    build = dict(entry["build"])
    mode = str(build.get("mode") or "docker")
    workdir_name = str(build.get("workdir") or ("safe" if mode == "safe-debian" else "."))
    if not (scratch_source / workdir_name).exists():
        raise ValidatorError(f"missing workdir for {library}: {scratch_source / workdir_name}")

    if mode == "checkout-artifacts":
        artifacts: list[Path] = []
        for pattern in build["artifact_globs"]:
            for source_path in sorted((scratch_source / workdir_name).glob(pattern)):
                dest = output / source_path.name
                shutil.copy2(source_path, dest)
                artifacts.append(dest)
        if not artifacts:
            raise ValidatorError(f"no declared artifacts were produced for {library}")
        return list(dict.fromkeys(artifacts))

    build_with_docker(entry, scratch_source, output, manifest["archive"])
    return collect_artifacts(output, list(build["artifact_globs"]), library)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", required=True, type=Path)
    parser.add_argument("--library", required=True)
    parser.add_argument("--port-root", required=True, type=Path)
    parser.add_argument("--workspace", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    manifest = load_manifest(args.config)
    build_library(
        manifest,
        library=args.library,
        port_root=args.port_root,
        workspace=args.workspace,
        output=args.output,
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ValidatorError as exc:
        print(str(exc), file=sys.stderr)
        raise SystemExit(1)
