from __future__ import annotations

import os
import shutil
import subprocess
from pathlib import Path
from urllib.parse import quote

from tools import ValidatorError, run


def effective_github_token(env: dict[str, str] | None = None) -> str:
    source = os.environ if env is None else env
    for name in ("GH_TOKEN", "SAFELIBS_REPO_TOKEN"):
        value = source.get(name, "")
        if value.strip():
            return value.strip()
    if shutil.which("gh") is None:
        return ""
    gh_env = os.environ.copy()
    if env is not None:
        gh_env.update(env)
    gh_env["GH_PROMPT_DISABLED"] = "1"
    completed = subprocess.run(
        ["gh", "auth", "token"],
        env=gh_env,
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode != 0:
        return ""
    return completed.stdout.strip()


def github_git_url(
    github_repo: str,
    env: dict[str, str] | None = None,
    *,
    allow_interactive_fallback: bool = False,
) -> str:
    token = effective_github_token(env)
    if token:
        return f"https://x-access-token:{quote(token, safe='')}@github.com/{github_repo}.git"
    if allow_interactive_fallback:
        return f"git@github.com:{github_repo}.git"
    raise ValidatorError(
        f"no non-interactive GitHub credential available for {github_repo}; "
        "set GH_TOKEN or SAFELIBS_REPO_TOKEN, or log in with gh"
    )


def git_env(
    extra_env: dict[str, str] | None = None,
    *,
    allow_prompt: bool = False,
) -> dict[str, str]:
    env = os.environ.copy()
    if extra_env:
        env.update(extra_env)
    if allow_prompt:
        env.pop("GIT_TERMINAL_PROMPT", None)
        env.pop("GIT_SSH_COMMAND", None)
    else:
        env["GIT_TERMINAL_PROMPT"] = "0"
        env.setdefault("GIT_SSH_COMMAND", "ssh -oBatchMode=yes")
    return env


def run_git(
    args: list[str],
    *,
    cwd: Path | None = None,
    env: dict[str, str] | None = None,
    capture_output: bool = False,
    allow_prompt: bool = False,
) -> None:
    run(
        args,
        cwd=cwd,
        env=git_env(env, allow_prompt=allow_prompt),
        capture_output=capture_output,
    )
