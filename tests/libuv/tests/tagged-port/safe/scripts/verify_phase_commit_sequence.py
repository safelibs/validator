#!/usr/bin/env python3
import argparse
import subprocess
import sys
from pathlib import Path


def fail(message: str) -> "NoReturn":
    print(message, file=sys.stderr)
    raise SystemExit(1)


def matching_phase(subject: str, phase_ids: list[str]) -> tuple[int, str]:
    for index, phase_id in enumerate(phase_ids):
        if subject.startswith(phase_id):
            return index, phase_id
    fail(f"commit subject does not begin with an allowed phase id: {subject}")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Verify first-parent commit subjects for the current workflow run."
    )
    parser.add_argument("--base-file", required=True, help="Path to workflow-run-base.txt")
    parser.add_argument("phase_ids", nargs="+", help="Allowed phase ids in monotonic order")
    args = parser.parse_args()

    base_file = Path(args.base_file)
    if not base_file.is_file():
        fail(f"missing base file: {base_file}")

    base_commit = base_file.read_text(encoding="utf-8").strip()
    if not base_commit:
        fail(f"base file is empty: {base_file}")

    try:
        subprocess.run(
            ["git", "rev-parse", "--verify", f"{base_commit}^{{commit}}"],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    except subprocess.CalledProcessError:
        fail(f"base commit is not valid: {base_commit}")

    result = subprocess.run(
        ["git", "log", "--first-parent", "--format=%H %s", f"{base_commit}..HEAD"],
        check=True,
        capture_output=True,
        text=True,
    )
    lines = [line for line in result.stdout.splitlines() if line.strip()]
    if not lines:
        fail(f"no commits found in first-parent range {base_commit}..HEAD")

    commits_newest_first = []
    for line in lines:
        parts = line.split(" ", 1)
        if len(parts) != 2 or not parts[1]:
            fail(f"unexpected git log line: {line}")
        commits_newest_first.append((parts[0], parts[1]))

    head_subject = commits_newest_first[0][1]
    if not head_subject.startswith(args.phase_ids[-1]):
        fail(
            "HEAD subject must begin with "
            f"{args.phase_ids[-1]}, got: {head_subject}"
        )

    commits_oldest_first = list(reversed(commits_newest_first))
    first_subject = commits_oldest_first[0][1]
    if not first_subject.startswith(args.phase_ids[0]):
        fail(
            "first commit in range must begin with "
            f"{args.phase_ids[0]}, got: {first_subject}"
        )

    seen_phase_ids = set()
    previous_index = -1
    for commit_hash, subject in commits_oldest_first:
        phase_index, phase_id = matching_phase(subject, args.phase_ids)
        if phase_index < previous_index:
            fail(
                "phase order regressed at "
                f"{commit_hash}: {subject}"
            )
        previous_index = phase_index
        seen_phase_ids.add(phase_id)

    missing = [phase_id for phase_id in args.phase_ids if phase_id not in seen_phase_ids]
    if missing:
        fail("missing phase ids in first-parent history: " + ", ".join(missing))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
