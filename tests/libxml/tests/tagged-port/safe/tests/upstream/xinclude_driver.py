#!/usr/bin/env python3

from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
import time
from dataclasses import asdict, dataclass
from pathlib import Path
from urllib.parse import unquote, urlparse


ROOT = Path(__file__).resolve().parents[3]
SUITE_DIR = ROOT / "original" / "xinclude-test-suite"
LOG_NAME = "check-xinclude-test-suite.log"
PYTHON_SITE = ROOT / "safe" / "target" / "stage" / "usr" / "lib" / "python3" / "dist-packages"
STAGE_LIB = next((ROOT / "safe" / "target" / "stage" / "usr" / "lib").glob("*/libxml2.so.2.9.14")).parent
ORIGINAL_LIB = ROOT / "original" / ".libs"


@dataclass
class Summary:
    total: int
    succeeded: int
    failed: int
    errors: int


def child_env(libdir: Path, *, allow_network: bool) -> dict[str, str]:
    env = os.environ.copy()
    env["PYTHONPATH"] = f"{PYTHON_SITE}:{env.get('PYTHONPATH', '')}".rstrip(":")
    env["LD_LIBRARY_PATH"] = f"{libdir}:{env.get('LD_LIBRARY_PATH', '')}".rstrip(":")
    if allow_network:
        env["LIBXML2_SAFE_ALLOW_NETWORK"] = "1"
    else:
        env.pop("LIBXML2_SAFE_ALLOW_NETWORK", None)
    return env


def run_child(libdir: Path, *, allow_network: bool) -> tuple[Summary, str]:
    with tempfile.TemporaryDirectory(prefix="xinclude-driver-") as tempdir:
        temp = Path(tempdir)
        summary_path = temp / "summary.json"
        proc = subprocess.run(
            [sys.executable, str(__file__), "--internal", str(summary_path)],
            cwd=temp,
            env=child_env(libdir, allow_network=allow_network),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=False,
        )
        if proc.returncode != 0:
            raise SystemExit(
                f"xinclude driver child failed with exit {proc.returncode}\n"
                f"stdout:\n{proc.stdout}\n"
                f"stderr:\n{proc.stderr}"
            )
        log_path = temp / LOG_NAME
        if not summary_path.is_file() or not log_path.is_file():
            raise SystemExit("xinclude driver child did not produce summary and log outputs")
        summary = Summary(**json.loads(summary_path.read_text(encoding="utf-8")))
        return summary, log_path.read_text(encoding="utf-8", errors="replace")


def ensure_matching_baseline() -> int:
    safe_summary, safe_log = run_child(STAGE_LIB, allow_network=True)
    original_summary, original_log = run_child(ORIGINAL_LIB, allow_network=False)

    log_path = Path.cwd() / LOG_NAME
    if log_path.exists():
        log_path.unlink()
    log_path.write_text(safe_log, encoding="utf-8")

    if safe_summary != original_summary or safe_log != original_log:
        print("XInclude suite diverged from original-linked baseline", file=sys.stderr)
        print(
            "safe   : "
            f"{safe_summary.total} tests, {safe_summary.succeeded} succeeded, "
            f"{safe_summary.failed} failed, {safe_summary.errors} errors",
            file=sys.stderr,
        )
        print(
            "original: "
            f"{original_summary.total} tests, {original_summary.succeeded} succeeded, "
            f"{original_summary.failed} failed, {original_summary.errors} errors",
            file=sys.stderr,
        )
        raise SystemExit(1)

    print("XInclude suite matched original-linked baseline")
    print(
        f"Totals: {safe_summary.total} tests, {safe_summary.succeeded} succeeded, "
        f"{safe_summary.failed} inherited failure, {safe_summary.errors} inherited errors."
    )
    return 0


def uri_to_path(value: str) -> Path:
    parsed = urlparse(value)
    if parsed.scheme == "file":
        return Path(unquote(parsed.path))
    return Path(value)


def suite_run(summary_path: Path) -> int:
    sys.path.insert(0, str(PYTHON_SITE))
    import libxml2

    log_path = Path.cwd() / LOG_NAME
    if log_path.exists():
        log_path.unlink()

    log = log_path.open("w", encoding="utf-8")
    os.chdir(SUITE_DIR)

    test_nr = 0
    test_succeed = 0
    test_failed = 0
    test_error = 0
    error_nr = 0
    error_msg = ""

    def error_handler(ctx, message):
        del ctx
        nonlocal error_nr
        nonlocal error_msg

        if "error:" in message:
            error_nr += 1
        if len(error_msg) < 300:
            prefix = "   >>" if not error_msg or error_msg.endswith("\n") else ""
            error_msg += prefix + message

    libxml2.registerErrorHandler(error_handler, None)

    def run_test(test, basedir):
        nonlocal test_nr
        nonlocal test_succeed
        nonlocal test_failed
        nonlocal test_error
        nonlocal error_nr
        nonlocal error_msg

        error_nr = 0
        error_msg = ""

        uri = test.prop("href")
        ident = test.prop("id")
        test_type = test.prop("type")
        if uri is None or ident is None or test_type is None:
            raise SystemExit("xinclude test case is missing href, id, or type")

        if basedir is not None:
            uri_value = f"{basedir}/{uri}"
        else:
            uri_value = uri

        uri_path = uri_to_path(uri_value)
        if not uri_path.is_file():
            print(f"Test {uri_value} missing: base {basedir} uri {uri}")
            return -1

        expected = None
        outputfile = None
        diff = None
        if test_type != "error":
            output = test.xpathEval("string(output)")
            if output in {"", "No output file."}:
                output = None
            if output is not None:
                if basedir is not None:
                    output = f"{basedir}/{output}"
                output_path = uri_to_path(output)
                if not output_path.is_file():
                    print(f"Result for {ident} missing: {output}")
                else:
                    expected = output_path.read_bytes()
                    outputfile = output_path

        try:
            doc = libxml2.parseFile(uri_value)
        except Exception:
            doc = None

        if doc is None:
            print(f"Failed to parse {uri_value}")
            res = -1
        else:
            res = doc.xincludeProcess()
            if res >= 0 and expected is not None:
                tmp = Path(".xinclude-driver.res")
                tmp.write_bytes(b"")
                doc.saveFile(str(tmp))
                result = tmp.read_bytes()
                if result != expected:
                    print(f"Result for {ident} differs")
                    diff_run = subprocess.run(
                        ["diff", str(outputfile), str(tmp)],
                        capture_output=True,
                        check=False,
                        text=True,
                    )
                    diff = diff_run.stdout or diff_run.stderr
                tmp.unlink(missing_ok=True)
            doc.freeDoc()

        test_nr += 1
        if test_type == "success":
            if res > 0:
                test_succeed += 1
            elif res == 0:
                test_failed += 1
                print(f"Test {ident}: no substitution done ???")
            else:
                test_error += 1
                print(f"Test {ident}: failed valid XInclude processing")
        elif test_type == "error":
            if res > 0:
                test_error += 1
                print(f"Test {ident}: failed to detect invalid XInclude processing")
            elif res == 0:
                test_failed += 1
                print(f"Test {ident}: Invalid but no substitution done")
            else:
                test_succeed += 1
        elif test_type == "optional":
            if res > 0:
                test_succeed += 1
            else:
                print(f"Test {ident}: failed optional test")

        if res != 1:
            log.write(f"Test ID {ident}\n")
            log.write(f"   File: {uri_value}\n")
            content = (test.content or "").rstrip("\n")
            log.write(f"   {test_type}:{content}\n\n")
            if error_msg:
                log.write(f"   ----\n{error_msg}   ----\n")
                error_msg = ""
            log.write("\n")
        if diff is not None:
            log.write(f"diff from test {ident}:\n")
            log.write(f"   -----------\n{diff}\n   -----------\n")
        return 0

    def run_test_cases(case):
        creator = case.prop("creator")
        if creator is not None:
            print("=>", creator)
        base = case.getBase(None)
        basedir = case.prop("basedir")
        if basedir is not None:
            base = libxml2.buildURI(basedir, base)
        test = case.children
        while test is not None:
            if test.name == "testcase":
                run_test(test, base)
            if test.name == "testcases":
                run_test_cases(test)
            test = test.next

    conf = libxml2.parseFile("testdescr.xml")
    if conf is None:
        raise SystemExit("Unable to load testdescr.xml")

    testsuite = conf.getRootElement()
    if testsuite.name != "testsuite":
        raise SystemExit("Expecting TESTSUITE root element: aborting")

    profile = testsuite.prop("PROFILE")
    if profile is not None:
        print(profile)

    start = time.time()
    case = testsuite.children
    while case is not None:
        if case.name == "testcases":
            old_test_nr = test_nr
            old_test_succeed = test_succeed
            old_test_failed = test_failed
            old_test_error = test_error
            run_test_cases(case)
            print(
                "   Ran %d tests: %d succeeded, %d failed and %d generated an error"
                % (
                    test_nr - old_test_nr,
                    test_succeed - old_test_succeed,
                    test_failed - old_test_failed,
                    test_error - old_test_error,
                )
            )
        case = case.next

    conf.freeDoc()
    log.close()

    print(
        "Ran %d tests: %d succeeded, %d failed and %d generated an error in %.2f s."
        % (test_nr, test_succeed, test_failed, test_error, time.time() - start)
    )

    summary_path.write_text(
        json.dumps(
            asdict(
                Summary(
                    total=test_nr,
                    succeeded=test_succeed,
                    failed=test_failed,
                    errors=test_error,
                )
            ),
            sort_keys=True,
        ),
        encoding="utf-8",
    )
    return 0


def main() -> int:
    if len(sys.argv) == 3 and sys.argv[1] == "--internal":
        return suite_run(Path(sys.argv[2]))
    if len(sys.argv) != 1:
        raise SystemExit("usage: xinclude_driver.py")
    return ensure_matching_baseline()


if __name__ == "__main__":
    raise SystemExit(main())
