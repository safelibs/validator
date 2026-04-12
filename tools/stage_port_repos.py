from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path

if __package__ in {None, ""}:
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from tools import ValidatorError, select_repositories
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
