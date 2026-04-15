from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path

if __package__ in {None, ""}:
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from tools import ValidatorError, run as run_command, select_repositories
from tools import github_auth
from tools.inventory import load_manifest


def local_ref_exists(repo_root: Path, ref: str) -> bool:
    completed = subprocess.run(
        ["git", "-C", str(repo_root), "rev-parse", "--verify", "--quiet", f"{ref}^{{}}"],
        env=github_auth.git_env(),
        text=True,
        capture_output=True,
        check=False,
    )
    return completed.returncode == 0


def remove_existing_checkout(path: Path) -> None:
    if path.exists():
        shutil.rmtree(path)
    path.parent.mkdir(parents=True, exist_ok=True)


def clone_from_source(source_repo: Path, dest_repo: Path) -> None:
    github_auth.run_git(["git", "clone", "--no-checkout", str(source_repo), str(dest_repo)])


def clone_from_remote(github_repo: str, dest_repo: Path) -> None:
    github_auth.run_git(
        ["git", "clone", "--no-checkout", github_auth.github_git_url(github_repo), str(dest_repo)]
    )


def fetch_exact_tag(dest_repo: Path, github_repo: str, ref: str) -> None:
    github_auth.run_git(
        [
            "git",
            "-C",
            str(dest_repo),
            "fetch",
            "--no-tags",
            github_auth.github_git_url(github_repo),
            f"{ref}:{ref}",
        ]
    )


def checkout_ref(dest_repo: Path, ref: str) -> None:
    github_auth.run_git(["git", "-C", str(dest_repo), "checkout", "--detach", ref])


def stage_libuv_prebuilt_runtime_archive(sibling_repo: Path, workspace: Path) -> None:
    source_archive = sibling_repo / "safe" / "target" / "release" / "libuv.a"
    if not source_archive.is_file():
        raise ValidatorError(
            f"missing libuv prebuilt runtime support archive in sibling repo: {source_archive}"
        )

    dest_archive = (
        workspace / "build-safe" / "libuv" / "source" / "safe" / "target" / "release" / "libuv.a"
    )
    dest_archive.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source_archive, dest_archive)


def _write_relocatable_pkgconfig(source_path: Path, dest_path: Path) -> None:
    rewritten_lines: list[str] = []
    replaced_prefix = False
    for line in source_path.read_text().splitlines():
        if line.startswith("prefix="):
            rewritten_lines.append("prefix=${pcfiledir}/../..")
            replaced_prefix = True
        else:
            rewritten_lines.append(line)

    if not replaced_prefix:
        raise ValidatorError(f"missing prefix= line in libvips pkg-config template: {source_path}")

    dest_path.parent.mkdir(parents=True, exist_ok=True)
    dest_path.write_text("\n".join(rewritten_lines) + "\n")


def _build_placeholder_shared_library(
    output_path: Path,
    *,
    soname: str,
    symbol_name: str,
) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    run_command(
        [
            "cc",
            "-shared",
            "-fPIC",
            f"-Wl,-soname,{soname}",
            "-x",
            "c",
            "-o",
            str(output_path),
            "-",
        ],
        input_text=f"int {symbol_name}(void) {{ return 0; }}\n",
        capture_output=True,
    )


def stage_libvips_reference_install(dest_repo: Path) -> None:
    source_include = dest_repo / "safe" / "include"
    source_pkgconfig = dest_repo / "safe" / "reference" / "pkgconfig"
    if not source_include.is_dir():
        raise ValidatorError(f"missing libvips staged include tree: {source_include}")
    if not (source_pkgconfig / "vips.pc").is_file():
        raise ValidatorError(f"missing libvips pkg-config template: {source_pkgconfig / 'vips.pc'}")
    if not (source_pkgconfig / "vips-cpp.pc").is_file():
        raise ValidatorError(
            f"missing libvips pkg-config template: {source_pkgconfig / 'vips-cpp.pc'}"
        )

    reference_root = dest_repo / "build-check-install"
    if reference_root.exists():
        shutil.rmtree(reference_root)

    shutil.copytree(source_include, reference_root / "include", symlinks=True)
    _write_relocatable_pkgconfig(source_pkgconfig / "vips.pc", reference_root / "lib" / "pkgconfig" / "vips.pc")
    _write_relocatable_pkgconfig(
        source_pkgconfig / "vips-cpp.pc",
        reference_root / "lib" / "pkgconfig" / "vips-cpp.pc",
    )

    _build_placeholder_shared_library(
        reference_root / "lib" / "libvips.so.42.17.1",
        soname="libvips.so.42",
        symbol_name="vips_reference_placeholder",
    )
    _build_placeholder_shared_library(
        reference_root / "lib" / "libvips-cpp.so.42.17.1",
        soname="libvips-cpp.so.42",
        symbol_name="vips_cpp_reference_placeholder",
    )

    symlinks = {
        reference_root / "lib" / "libvips.so.42": "libvips.so.42.17.1",
        reference_root / "lib" / "libvips.so": "libvips.so.42",
        reference_root / "lib" / "libvips-cpp.so.42": "libvips-cpp.so.42.17.1",
        reference_root / "lib" / "libvips-cpp.so": "libvips-cpp.so.42",
    }
    for symlink_path, target in symlinks.items():
        if symlink_path.exists() or symlink_path.is_symlink():
            symlink_path.unlink()
        symlink_path.symlink_to(target)


def stage_repository(
    entry: dict[str, object],
    *,
    workspace: Path,
    dest_root: Path,
    source_root: Path | None,
) -> None:
    workspace.mkdir(parents=True, exist_ok=True)
    library = str(entry["name"])
    ref = str(entry["ref"])
    dest_repo = dest_root / library
    remove_existing_checkout(dest_repo)

    try:
        sibling_repo: Path | None = None
        if source_root is not None:
            sibling_repo = source_root / str(entry["validator"]["sibling_repo"])
            if not sibling_repo.exists():
                raise ValidatorError(f"missing sibling source repo for {library}: {sibling_repo}")
            clone_from_source(sibling_repo, dest_repo)
            if not local_ref_exists(dest_repo, ref):
                fetch_exact_tag(dest_repo, str(entry["github_repo"]), ref)
        else:
            clone_from_remote(str(entry["github_repo"]), dest_repo)
        checkout_ref(dest_repo, ref)
    except ValidatorError as exc:
        raise ValidatorError(f"unable to stage {library} at {ref}: {exc}") from exc

    if not local_ref_exists(dest_repo, ref):
        raise ValidatorError(f"unable to stage {library}: missing checked out ref {ref}")

    if library == "libvips":
        stage_libvips_reference_install(dest_repo)
    if library == "libuv" and sibling_repo is not None:
        stage_libuv_prebuilt_runtime_archive(sibling_repo, workspace)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", required=True, type=Path)
    parser.add_argument("--workspace", required=True, type=Path)
    parser.add_argument("--dest-root", required=True, type=Path)
    parser.add_argument("--source-root", type=Path)
    parser.add_argument("--libraries", nargs="*")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    manifest = load_manifest(args.config)
    for entry in select_repositories(manifest, args.libraries):
        stage_repository(
            entry,
            workspace=args.workspace,
            dest_root=args.dest_root,
            source_root=args.source_root,
        )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ValidatorError as exc:
        print(str(exc), file=sys.stderr)
        raise SystemExit(1)
