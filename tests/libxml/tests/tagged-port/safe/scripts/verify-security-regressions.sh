#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
SUBSET="${1:-}"

python3 - "$ROOT" "$SUBSET" <<'PY'
import ctypes
import json
import lzma
import os
import subprocess
import sys
from pathlib import Path

root = Path(sys.argv[1])
subset = sys.argv[2]
sys.setrecursionlimit(max(sys.getrecursionlimit(), 5000))
all_path = root / "all_cves.json"
relevant_path = root / "relevant_cves.json"

all_data = json.loads(all_path.read_text(encoding="utf-8"))
relevant_data = json.loads(relevant_path.read_text(encoding="utf-8"))

all_ids = set(all_data.get("included_cve_ids", []))
record_ids = {record["cve_id"] for record in all_data.get("records", [])}
relevant_entries = relevant_data.get("relevant_cves", [])
relevant_ids = {entry["cve_id"] for entry in relevant_entries}

if not all_ids or not record_ids:
    raise SystemExit("all_cves.json is unexpectedly empty")
if not relevant_entries:
    raise SystemExit("relevant_cves.json is unexpectedly empty")
if all_ids != record_ids:
    raise SystemExit("all_cves.json included_cve_ids do not match records")
if relevant_ids - all_ids:
    missing = sorted(relevant_ids - all_ids)
    raise SystemExit(f"relevant_cves.json contains CVEs absent from all_cves.json: {missing[:10]}")

source_file = Path(relevant_data.get("source_file", ""))
if source_file.name != all_path.name:
    raise SystemExit("relevant_cves.json source_file is not anchored to all_cves.json")

included_count = all_data.get("counts", {}).get("included_cves")
if included_count is not None and included_count != len(all_ids):
    raise SystemExit("all_cves.json counts.included_cves does not match included_cve_ids")

relevant_count = relevant_data.get("summary", {}).get("relevant_non_memory_corruption_cves")
if relevant_count is not None and relevant_count != len(relevant_entries):
    raise SystemExit("relevant_cves.json summary count does not match relevant_cves entries")

print(
    "security regression corpus loaded "
    f"{len(relevant_entries)} relevant CVEs from {len(all_ids)} authoritative corpus entries"
)

valid_subsets = {"", "all", "tree-io", "xpath-valid", "cli-shell", "schema"}
if subset not in valid_subsets:
    raise SystemExit(f"unknown security subset {subset!r}")


def selected(name: str) -> bool:
    return subset in {"", "all", name}

stage_candidates = sorted((root / "safe/target/stage").glob("usr/lib/*/libxml2.so.2.9.14"))
if not stage_candidates:
    raise SystemExit("security checks require a staged libxml2.so.2.9.14")

os.environ.pop("LIBXML2_SAFE_ALLOW_NETWORK", None)
os.environ.pop("XML_CATALOG_FILES", None)
os.environ.pop("SGML_CATALOG_FILES", None)

stage_lib = stage_candidates[0]
stage_libdir = stage_lib.parent
stage_bindir = root / "safe/target/stage/usr/bin"
stage_xmllint = stage_bindir / "xmllint"
stage_xmlcatalog = stage_bindir / "xmlcatalog"
lib = ctypes.CDLL(str(stage_lib))

char_pp = ctypes.POINTER(ctypes.c_char_p)

def stage_env() -> dict[str, str]:
    env = os.environ.copy()
    env["LD_LIBRARY_PATH"] = f"{stage_libdir}:{env.get('LD_LIBRARY_PATH', '')}".rstrip(":")
    env.pop("LIBXML2_SAFE_ALLOW_NETWORK", None)
    env.pop("XML_CATALOG_FILES", None)
    env.pop("SGML_CATALOG_FILES", None)
    return env


def run_stage_command(
    label: str,
    argv: list[str],
    cwd: Path,
    *,
    timeout: int = 5,
    expect_success: bool | None = None,
) -> subprocess.CompletedProcess[str]:
    try:
        completed = subprocess.run(
            argv,
            cwd=cwd,
            env=stage_env(),
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=timeout,
            check=False,
        )
    except subprocess.TimeoutExpired as exc:
        raise SystemExit(f"{label} timed out after {timeout}s") from exc

    if expect_success is True and completed.returncode != 0:
        raise SystemExit(
            f"{label} failed with exit {completed.returncode}\n"
            f"stdout:\n{completed.stdout}\n"
            f"stderr:\n{completed.stderr}"
        )
    if expect_success is False and completed.returncode == 0:
        raise SystemExit(
            f"{label} unexpectedly succeeded\n"
            f"stdout:\n{completed.stdout}\n"
            f"stderr:\n{completed.stderr}"
        )
    return completed


def require_recoverable_failure(label: str, completed: subprocess.CompletedProcess[str]) -> None:
    if completed.returncode in {-11, -6, 134, 139}:
        raise SystemExit(
            f"{label} terminated via crash-like exit {completed.returncode}\n"
            f"stdout:\n{completed.stdout}\n"
            f"stderr:\n{completed.stderr}"
        )
    if not completed.stdout.strip() and not completed.stderr.strip():
        raise SystemExit(f"{label} failed without any diagnostic output")


if selected("tree-io"):
    lib.xmlNanoHTTPOpen.argtypes = [ctypes.c_char_p, char_pp]
    lib.xmlNanoHTTPOpen.restype = ctypes.c_void_p
    lib.xmlNanoFTPConnectTo.argtypes = [ctypes.c_char_p, ctypes.c_int]
    lib.xmlNanoFTPConnectTo.restype = ctypes.c_void_p
    lib.xmlLoadExternalEntity.argtypes = [ctypes.c_char_p, ctypes.c_char_p, ctypes.c_void_p]
    lib.xmlLoadExternalEntity.restype = ctypes.c_void_p
    lib.xmlParserInputBufferCreateFilename.argtypes = [ctypes.c_char_p, ctypes.c_int]
    lib.xmlParserInputBufferCreateFilename.restype = ctypes.c_void_p
    lib.xmlFreeParserInputBuffer.argtypes = [ctypes.c_void_p]
    lib.xmlFreeParserInputBuffer.restype = None
    lib.__libxml2_xzopen.argtypes = [ctypes.c_char_p, ctypes.c_char_p]
    lib.__libxml2_xzopen.restype = ctypes.c_void_p
    lib.__libxml2_xzread.argtypes = [ctypes.c_void_p, ctypes.c_void_p, ctypes.c_uint]
    lib.__libxml2_xzread.restype = ctypes.c_int
    lib.__libxml2_xzclose.argtypes = [ctypes.c_void_p]
    lib.__libxml2_xzclose.restype = ctypes.c_int

    content_type = ctypes.c_char_p()
    http_ctx = lib.xmlNanoHTTPOpen(b"http://example.com/", ctypes.byref(content_type))
    if http_ctx or content_type.value:
        raise SystemExit("xmlNanoHTTPOpen unexpectedly permitted a network URL")

    ftp_ctx = lib.xmlNanoFTPConnectTo(b"example.com", 21)
    if ftp_ctx:
        raise SystemExit("xmlNanoFTPConnectTo unexpectedly permitted a network connection")

    loaded = lib.xmlLoadExternalEntity(b"http://example.com/ext.dtd", None, None)
    if loaded:
        raise SystemExit("xmlLoadExternalEntity unexpectedly permitted a network URL")

    local_path = root / "original/test/URI/uri.data"
    local_buf = lib.xmlParserInputBufferCreateFilename(str(local_path).encode(), 0)
    if not local_buf:
        raise SystemExit(f"xmlParserInputBufferCreateFilename failed for local path {local_path}")
    lib.xmlFreeParserInputBuffer(local_buf)

    remote_buf = lib.xmlParserInputBufferCreateFilename(b"http://example.com/doc.xml", 0)
    if remote_buf:
        raise SystemExit("xmlParserInputBufferCreateFilename unexpectedly permitted a network URL")

    xz_budget = 8 * 1024 * 1024
    scratch = root / "safe/target/security-regressions"
    scratch.mkdir(parents=True, exist_ok=True)
    xz_path = scratch / "oversized-output.xz"
    xz_path.write_bytes(lzma.compress(b"A" * (xz_budget + 1024 * 1024)))

    xz_handle = lib.__libxml2_xzopen(str(xz_path).encode(), b"rb")
    if not xz_handle:
        raise SystemExit("failed to open generated xz regression fixture")

    chunk = ctypes.create_string_buffer(64 * 1024)
    total = 0
    iterations = 0
    last_ret = 0
    while True:
        ret = lib.__libxml2_xzread(xz_handle, chunk, len(chunk))
        iterations += 1
        if ret <= 0:
            last_ret = ret
            break
        total += ret
        if iterations > 10_000:
            raise SystemExit("xz regression fixture exceeded iteration budget")

    lib.__libxml2_xzclose(xz_handle)

    if total > xz_budget:
        raise SystemExit(f"xz output budget exceeded: produced {total} bytes with budget {xz_budget}")
    if last_ret != -1:
        raise SystemExit(f"xz regression fixture did not terminate with a hard stop: last read={last_ret}")

    print("tree-io security checks passed: direct network loads blocked and xz output budget enforced")


if selected("xpath-valid"):
    security_root = root / "safe/tests/security"
    catalog_dir = security_root / "catalog"
    pattern_dir = security_root / "pattern"
    xinclude_dir = security_root / "xinclude"
    xpath_dir = security_root / "xpath"

    for path in (
        stage_xmllint,
        stage_xmlcatalog,
        catalog_dir / "duplicate-next.xml",
        catalog_dir / "leaf.xml",
        catalog_dir / "loop-a.xml",
        catalog_dir / "loop-b.xml",
        pattern_dir / "child-axis.xml",
        xinclude_dir / "remote.xml",
        xinclude_dir / "self.xml",
        xpath_dir / "doc.xml",
        xpath_dir / "malformed.expr",
        xpath_dir / "recurse.expr",
    ):
        if not path.exists():
            raise SystemExit(f"missing xpath-valid security fixture or tool: {path}")

    duplicate_result = run_stage_command(
        "catalog duplicate nextCatalog",
        [str(stage_xmlcatalog), "duplicate-next.xml", "urn:dup-target"],
        catalog_dir,
        expect_success=True,
    )
    duplicate_lines = [line.strip() for line in duplicate_result.stdout.splitlines() if line.strip()]
    if not duplicate_lines or duplicate_lines[-1] != "file:///resolved/duplicate-target":
        raise SystemExit(
            "catalog duplicate nextCatalog fixture resolved unexpectedly:\n"
            f"stdout:\n{duplicate_result.stdout}\n"
            f"stderr:\n{duplicate_result.stderr}"
        )

    run_stage_command(
        "catalog recursive nextCatalog loop",
        [str(stage_xmlcatalog), "loop-a.xml", "urn:missing"],
        catalog_dir,
        expect_success=False,
    )
    run_stage_command(
        "catalog upstream recursive sgml",
        [str(stage_xmlcatalog), "recursive.sgml", "urn:missing"],
        root / "original/test/catalogs",
        expect_success=False,
    )

    run_stage_command(
        "xinclude remote nonet",
        [str(stage_xmllint), "--noout", "--nonet", "--xinclude", "remote.xml"],
        xinclude_dir,
        expect_success=False,
    )
    run_stage_command(
        "xinclude self recursion",
        [str(stage_xmllint), "--noout", "--nonet", "--xinclude", "self.xml"],
        xinclude_dir,
        expect_success=False,
    )

    class XmlError(ctypes.Structure):
        _fields_ = [
            ("domain", ctypes.c_int),
            ("code", ctypes.c_int),
            ("message", ctypes.c_char_p),
            ("level", ctypes.c_int),
            ("file", ctypes.c_char_p),
            ("line", ctypes.c_int),
            ("str1", ctypes.c_char_p),
            ("str2", ctypes.c_char_p),
            ("str3", ctypes.c_char_p),
            ("int1", ctypes.c_int),
            ("int2", ctypes.c_int),
            ("ctxt", ctypes.c_void_p),
            ("node", ctypes.c_void_p),
        ]


    class XmlXPathContext(ctypes.Structure):
        pass


    class XmlXPathParserContext(ctypes.Structure):
        pass


    XmlXPathContext._fields_ = [
        ("doc", ctypes.c_void_p),
        ("node", ctypes.c_void_p),
        ("nb_variables_unused", ctypes.c_int),
        ("max_variables_unused", ctypes.c_int),
        ("varHash", ctypes.c_void_p),
        ("nb_types", ctypes.c_int),
        ("max_types", ctypes.c_int),
        ("types", ctypes.c_void_p),
        ("nb_funcs_unused", ctypes.c_int),
        ("max_funcs_unused", ctypes.c_int),
        ("funcHash", ctypes.c_void_p),
        ("nb_axis", ctypes.c_int),
        ("max_axis", ctypes.c_int),
        ("axis", ctypes.c_void_p),
        ("namespaces", ctypes.c_void_p),
        ("nsNr", ctypes.c_int),
        ("user", ctypes.c_void_p),
        ("contextSize", ctypes.c_int),
        ("proximityPosition", ctypes.c_int),
        ("xptr", ctypes.c_int),
        ("here", ctypes.c_void_p),
        ("origin", ctypes.c_void_p),
        ("nsHash", ctypes.c_void_p),
        ("varLookupFunc", ctypes.c_void_p),
        ("varLookupData", ctypes.c_void_p),
        ("extra", ctypes.c_void_p),
        ("function", ctypes.c_char_p),
        ("functionURI", ctypes.c_char_p),
        ("funcLookupFunc", ctypes.c_void_p),
        ("funcLookupData", ctypes.c_void_p),
        ("tmpNsList", ctypes.c_void_p),
        ("tmpNsNr", ctypes.c_int),
        ("userData", ctypes.c_void_p),
        ("error", ctypes.c_void_p),
        ("lastError", XmlError),
        ("debugNode", ctypes.c_void_p),
        ("dict", ctypes.c_void_p),
        ("flags", ctypes.c_int),
        ("cache", ctypes.c_void_p),
        ("opLimit", ctypes.c_ulong),
        ("opCount", ctypes.c_ulong),
        ("depth", ctypes.c_int),
    ]

    XmlXPathParserContext._fields_ = [
        ("cur", ctypes.c_void_p),
        ("base", ctypes.c_void_p),
        ("error", ctypes.c_int),
        ("context", ctypes.POINTER(XmlXPathContext)),
    ]

    xpath_func_t = ctypes.CFUNCTYPE(None, ctypes.POINTER(XmlXPathParserContext), ctypes.c_int)

    lib.xmlReadFile.argtypes = [ctypes.c_char_p, ctypes.c_char_p, ctypes.c_int]
    lib.xmlReadFile.restype = ctypes.c_void_p
    lib.xmlReadMemory.argtypes = [
        ctypes.c_char_p,
        ctypes.c_int,
        ctypes.c_char_p,
        ctypes.c_char_p,
        ctypes.c_int,
    ]
    lib.xmlReadMemory.restype = ctypes.c_void_p
    lib.xmlFreeDoc.argtypes = [ctypes.c_void_p]
    lib.xmlFreeDoc.restype = None
    lib.xmlDocGetRootElement.argtypes = [ctypes.c_void_p]
    lib.xmlDocGetRootElement.restype = ctypes.c_void_p
    lib.xmlFirstElementChild.argtypes = [ctypes.c_void_p]
    lib.xmlFirstElementChild.restype = ctypes.c_void_p
    lib.xmlXPathNewContext.argtypes = [ctypes.c_void_p]
    lib.xmlXPathNewContext.restype = ctypes.POINTER(XmlXPathContext)
    lib.xmlXPathFreeContext.argtypes = [ctypes.POINTER(XmlXPathContext)]
    lib.xmlXPathFreeContext.restype = None
    lib.xmlXPathEvalExpression.argtypes = [ctypes.c_char_p, ctypes.POINTER(XmlXPathContext)]
    lib.xmlXPathEvalExpression.restype = ctypes.c_void_p
    lib.xmlXPathRegisterFunc.argtypes = [ctypes.POINTER(XmlXPathContext), ctypes.c_char_p, xpath_func_t]
    lib.xmlXPathRegisterFunc.restype = ctypes.c_int
    lib.xmlXPathNewBoolean.argtypes = [ctypes.c_int]
    lib.xmlXPathNewBoolean.restype = ctypes.c_void_p
    lib.valuePush.argtypes = [ctypes.POINTER(XmlXPathParserContext), ctypes.c_void_p]
    lib.valuePush.restype = ctypes.c_int
    lib.xmlXPathFreeObject.argtypes = [ctypes.c_void_p]
    lib.xmlXPathFreeObject.restype = None
    lib.xmlPatterncompile.argtypes = [ctypes.c_char_p, ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
    lib.xmlPatterncompile.restype = ctypes.c_void_p
    lib.xmlPatternMatch.argtypes = [ctypes.c_void_p, ctypes.c_void_p]
    lib.xmlPatternMatch.restype = ctypes.c_int
    lib.xmlFreePattern.argtypes = [ctypes.c_void_p]
    lib.xmlFreePattern.restype = None

    xpath_doc = lib.xmlReadFile(str(xpath_dir / "doc.xml").encode(), None, 0)
    if not xpath_doc:
        raise SystemExit("failed to parse xpath security fixture document")

    xpath_ctx = lib.xmlXPathNewContext(xpath_doc)
    if not xpath_ctx:
        lib.xmlFreeDoc(xpath_doc)
        raise SystemExit("failed to create XPath context for security regression checks")

    malformed_expr = (xpath_dir / "malformed.expr").read_bytes().strip()
    malformed_result = lib.xmlXPathEvalExpression(malformed_expr, xpath_ctx)
    if malformed_result:
        lib.xmlXPathFreeObject(malformed_result)
        lib.xmlXPathFreeContext(xpath_ctx)
        lib.xmlFreeDoc(xpath_doc)
        raise SystemExit("malformed XPath expression unexpectedly evaluated successfully")

    recursive_expr = (xpath_dir / "recurse.expr").read_bytes().strip()
    recursive_state = {"calls": 0, "hit_limit": False, "errors": []}
    xpath_ctx.contents.depth = 4996

    @xpath_func_t
    def recurse_function(parser_ctxt, nargs):
        del nargs
        try:
            recursive_state["calls"] += 1
            if not parser_ctxt:
                recursive_state["errors"].append("recursive XPath callback received a null parser context")
            elif not recursive_state["hit_limit"]:
                inner_result = lib.xmlXPathEvalExpression(recursive_expr, parser_ctxt.contents.context)
                if inner_result:
                    lib.xmlXPathFreeObject(inner_result)
                else:
                    recursive_state["hit_limit"] = True

            boolean_obj = lib.xmlXPathNewBoolean(1 if recursive_state["hit_limit"] else 0)
            if not boolean_obj:
                recursive_state["errors"].append("xmlXPathNewBoolean failed in recursive callback")
            elif parser_ctxt and lib.valuePush(parser_ctxt, boolean_obj) < 0:
                recursive_state["errors"].append("valuePush failed in recursive callback")
                lib.xmlXPathFreeObject(boolean_obj)
        except Exception as exc:  # pragma: no cover - fatal test harness guard
            recursive_state["errors"].append(str(exc))

    register_rc = lib.xmlXPathRegisterFunc(xpath_ctx, b"recurse", recurse_function)
    if register_rc != 0:
        lib.xmlXPathFreeContext(xpath_ctx)
        lib.xmlFreeDoc(xpath_doc)
        raise SystemExit(f"xmlXPathRegisterFunc failed for recursive regression fixture: rc={register_rc}")

    recursive_result = lib.xmlXPathEvalExpression(recursive_expr, xpath_ctx)
    if recursive_result:
        lib.xmlXPathFreeObject(recursive_result)

    lib.xmlXPathFreeContext(xpath_ctx)
    lib.xmlFreeDoc(xpath_doc)

    if recursive_state["errors"]:
        raise SystemExit(
            "recursive XPath regression harness failed:\n" + "\n".join(recursive_state["errors"])
        )
    if recursive_state["calls"] < 2:
        raise SystemExit("recursive XPath regression did not reach a recursive re-entry")
    if not recursive_state["hit_limit"]:
        raise SystemExit(
            "recursive XPath regression never hit the shared depth budget; "
            "the CVE-2025-9714 guard may be bypassed"
        )

    pattern_doc = lib.xmlReadFile(str(pattern_dir / "child-axis.xml").encode(), None, 0)
    if not pattern_doc:
        raise SystemExit("failed to parse child-axis pattern regression fixture")
    pattern_root = lib.xmlDocGetRootElement(pattern_doc)
    pattern_child = lib.xmlFirstElementChild(pattern_root)
    if not pattern_root or not pattern_child:
        lib.xmlFreeDoc(pattern_doc)
        raise SystemExit("child-axis pattern regression fixture did not produce expected root/child nodes")

    default_pattern = lib.xmlPatterncompile(b"root/child", None, 0, None)
    explicit_child_pattern = lib.xmlPatterncompile(b"child::root/child::child", None, 0, None)
    if not default_pattern or not explicit_child_pattern:
        if default_pattern:
            lib.xmlFreePattern(default_pattern)
        if explicit_child_pattern:
            lib.xmlFreePattern(explicit_child_pattern)
        lib.xmlFreeDoc(pattern_doc)
        raise SystemExit("xmlPatterncompile failed for the child-axis regression fixture")
    if lib.xmlPatternMatch(default_pattern, pattern_child) != 1:
        lib.xmlFreePattern(default_pattern)
        lib.xmlFreePattern(explicit_child_pattern)
        lib.xmlFreeDoc(pattern_doc)
        raise SystemExit("default child pattern no longer matches the child-axis regression fixture")
    if lib.xmlPatternMatch(explicit_child_pattern, pattern_child) != 1:
        lib.xmlFreePattern(default_pattern)
        lib.xmlFreePattern(explicit_child_pattern)
        lib.xmlFreeDoc(pattern_doc)
        raise SystemExit(
            "explicit child-axis pattern failed to match the regression fixture; "
            "the CVE-2025-27113 fix regressed"
        )
    if lib.xmlPatternMatch(explicit_child_pattern, pattern_root) == 1:
        lib.xmlFreePattern(default_pattern)
        lib.xmlFreePattern(explicit_child_pattern)
        lib.xmlFreeDoc(pattern_doc)
        raise SystemExit("explicit child-axis pattern incorrectly matched the document root")
    lib.xmlFreePattern(default_pattern)
    lib.xmlFreePattern(explicit_child_pattern)
    lib.xmlFreeDoc(pattern_doc)

    print(
        "xpath-valid security checks passed: catalog recursion/duplicate-next limits "
        "hold, XInclude honors nonet and self-recursion failures, recursive XPath "
        "re-entry stops with a recoverable depth error, and explicit child-axis "
        "patterns still compile and match correctly"
    )


if selected("cli-shell"):
    script_dir = root / "original" / "test" / "scripts"
    result_dir = root / "original" / "result" / "scripts"
    script_path = script_dir / "long_command.script"
    xml_path = script_dir / "long_command.xml"
    expected_path = result_dir / "long_command"

    for path in (stage_xmllint, script_path, xml_path, expected_path):
        if not path.exists():
            raise SystemExit(f"missing cli-shell security fixture or tool: {path}")

    try:
        completed = subprocess.run(
            [str(stage_xmllint), "--shell", str(xml_path)],
            cwd=script_dir,
            env=stage_env(),
            text=True,
            stdin=script_path.open("r", encoding="utf-8"),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=10,
            check=False,
        )
    except subprocess.TimeoutExpired as exc:
        raise SystemExit("xmllint shell long command fixture timed out after 10s") from exc

    if completed.returncode != 0:
        raise SystemExit(
            f"xmllint shell long command fixture failed with exit {completed.returncode}\n"
            f"stdout:\n{completed.stdout}\n"
            f"stderr:\n{completed.stderr}"
        )

    expected = expected_path.read_text(encoding="utf-8")
    if completed.stdout != expected:
        raise SystemExit(
            "xmllint shell long command fixture drifted from the checked-in expected output:\n"
            f"stdout:\n{completed.stdout}\n"
            f"expected:\n{expected}"
        )

    print("cli-shell security checks passed: bounded long-command shell fixture matches expected output")


if selected("schema"):
    security_root = root / "safe/tests/security"
    schema_dir = security_root / "schema"
    relaxng_dir = security_root / "relaxng"
    schematron_dir = root / "original" / "test" / "schematron"
    schematron_result_dir = root / "original" / "result" / "schematron"
    include_limit = root / "original/test/relaxng/include/include-limit.rng"

    for path in (
        stage_xmllint,
        schema_dir / "issue491_0.xsd",
        schema_dir / "issue491_0.xml",
        relaxng_dir / "invalid.rng",
        relaxng_dir / "instance.xml",
        schematron_dir / "cve-2025-49794.sct",
        schematron_dir / "cve-2025-49794_0.xml",
        schematron_result_dir / "cve-2025-49794_0.err",
        schematron_dir / "cve-2025-49796.sct",
        schematron_dir / "cve-2025-49796_0.xml",
        schematron_result_dir / "cve-2025-49796_0.err",
        include_limit,
    ):
        if not path.exists():
            raise SystemExit(f"missing schema security fixture or tool: {path}")

    issue491_result = run_stage_command(
        "schema issue491 invalid complex type",
        [
            str(stage_xmllint),
            "--noout",
            "--schema",
            str(schema_dir / "issue491_0.xsd"),
            str(schema_dir / "issue491_0.xml"),
        ],
        root,
        expect_success=False,
    )
    require_recoverable_failure("schema issue491 invalid complex type", issue491_result)

    invalid_rng_result = run_stage_command(
        "relaxng malformed schema",
        [
            str(stage_xmllint),
            "--noout",
            "--relaxng",
            str(relaxng_dir / "invalid.rng"),
            str(relaxng_dir / "instance.xml"),
        ],
        root,
        expect_success=False,
    )
    require_recoverable_failure("relaxng malformed schema", invalid_rng_result)

    lib.xmlRelaxNGNewParserCtxt.argtypes = [ctypes.c_char_p]
    lib.xmlRelaxNGNewParserCtxt.restype = ctypes.c_void_p
    lib.xmlRelaxParserSetIncLImit.argtypes = [ctypes.c_void_p, ctypes.c_int]
    lib.xmlRelaxParserSetIncLImit.restype = ctypes.c_int
    lib.xmlRelaxNGParse.argtypes = [ctypes.c_void_p]
    lib.xmlRelaxNGParse.restype = ctypes.c_void_p
    lib.xmlRelaxNGFreeParserCtxt.argtypes = [ctypes.c_void_p]
    lib.xmlRelaxNGFreeParserCtxt.restype = None
    lib.xmlRelaxNGFree.argtypes = [ctypes.c_void_p]
    lib.xmlRelaxNGFree.restype = None

    ctxt = lib.xmlRelaxNGNewParserCtxt(str(include_limit).encode())
    if not ctxt:
        raise SystemExit("xmlRelaxNGNewParserCtxt failed for include limit regression fixture")
    if lib.xmlRelaxParserSetIncLImit(ctxt, 2) != 0:
        lib.xmlRelaxNGFreeParserCtxt(ctxt)
        raise SystemExit("xmlRelaxParserSetIncLImit rejected a valid limit of 2")
    schema = lib.xmlRelaxNGParse(ctxt)
    if schema:
        lib.xmlRelaxNGFree(schema)
        lib.xmlRelaxNGFreeParserCtxt(ctxt)
        raise SystemExit("xmlRelaxNGParse unexpectedly ignored include limit 2")
    lib.xmlRelaxNGFreeParserCtxt(ctxt)

    ctxt = lib.xmlRelaxNGNewParserCtxt(str(include_limit).encode())
    if not ctxt:
        raise SystemExit("xmlRelaxNGNewParserCtxt failed on second include limit attempt")
    if lib.xmlRelaxParserSetIncLImit(ctxt, 3) != 0:
        lib.xmlRelaxNGFreeParserCtxt(ctxt)
        raise SystemExit("xmlRelaxParserSetIncLImit rejected a valid limit of 3")
    schema = lib.xmlRelaxNGParse(ctxt)
    if not schema:
        lib.xmlRelaxNGFreeParserCtxt(ctxt)
        raise SystemExit("xmlRelaxNGParse failed with include limit 3; expected successful bounded parse")
    lib.xmlRelaxNGFree(schema)
    lib.xmlRelaxNGFreeParserCtxt(ctxt)

    for case_name, schema_name, xml_name, err_name in (
        (
            "schematron report-output use-after-free",
            "cve-2025-49794.sct",
            "cve-2025-49794_0.xml",
            "cve-2025-49794_0.err",
        ),
        (
            "schematron report-output node-type confusion",
            "cve-2025-49796.sct",
            "cve-2025-49796_0.xml",
            "cve-2025-49796_0.err",
        ),
    ):
        completed = run_stage_command(
            case_name,
            [
                str(stage_xmllint),
                "--schematron",
                f"./test/schematron/{schema_name}",
                f"./test/schematron/{xml_name}",
            ],
            root / "original",
            expect_success=False,
        )
        require_recoverable_failure(case_name, completed)
        expected_stderr = (schematron_result_dir / err_name).read_text(encoding="utf-8")
        if completed.stderr != expected_stderr:
            raise SystemExit(
                f"{case_name} drifted from the checked-in regression oracle:\n"
                f"stderr:\n{completed.stderr}\n"
                f"expected:\n{expected_stderr}"
            )

    print(
        "schema security checks passed: malformed XSD and RNG inputs fail with "
        "recoverable diagnostics, RelaxNG include depth limits are enforced, "
        "and the patch-added Schematron regression fixtures still fail safely"
    )
PY
