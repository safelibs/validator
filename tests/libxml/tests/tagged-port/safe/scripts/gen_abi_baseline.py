#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import re
import shlex
import subprocess
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ORIGINAL = ROOT / "original"
SAFE = ROOT / "safe"
BASELINE = SAFE / "abi" / "baseline"
EXPORTS = BASELINE / "exports.txt"
LAYOUTS = BASELINE / "layouts.json"
ENUMS = BASELINE / "enums.json"
PKGCONFIG = BASELINE / "pkgconfig.txt"
XML2_CONFIG = BASELINE / "xml2-config.txt"
XML2CONF = BASELINE / "xml2Conf.sh.txt"
SONAME = BASELINE / "soname.txt"
XMLLINT_HELP = BASELINE / "xmllint-help.txt"
XMLCATALOG_HELP = BASELINE / "xmlcatalog-help.txt"
PACKAGE_FILES = BASELINE / "package-files.txt"
SYMS = SAFE / "abi" / "libxml2.syms"


def main() -> None:
    BASELINE.mkdir(parents=True, exist_ok=True)
    (SAFE / "abi").mkdir(parents=True, exist_ok=True)

    actual_exports = parse_objdump_exports(ORIGINAL / ".libs" / "libxml2.so.2.9.14")
    debian_exports = parse_debian_symbols(ORIGINAL / "debian" / "libxml2.symbols")
    original_syms = (ORIGINAL / "libxml2.syms").read_text(encoding="utf-8")
    original_syms_names = set(re.findall(r"^\s*([A-Za-z_][A-Za-z0-9_]*)\s*;", original_syms, re.M))

    missing_debian = sorted(name for name in debian_exports if name not in actual_exports)
    if missing_debian:
        raise SystemExit(f"debian symbol inventory contains missing exports: {missing_debian[:20]}")

    mismatched = sorted(
        name
        for name, version in debian_exports.items()
        if actual_exports.get(name) != version
    )
    if mismatched:
        raise SystemExit(f"debian symbol versions differ from original dso: {mismatched[:20]}")

    EXPORTS.write_text(
        "".join(f"{name}@{version}\n" for name, version in sorted(actual_exports.items())),
        encoding="utf-8",
    )

    missing_base = sorted(
        name
        for name, version in actual_exports.items()
        if name not in original_syms_names and version == "Base"
    )
    missing_non_base = sorted(
        name
        for name, version in actual_exports.items()
        if name not in original_syms_names and version != "Base"
    )
    if missing_non_base:
        raise SystemExit(
            "original/libxml2.syms is missing non-Base symbols that need a manual phase-1 update: "
            + ", ".join(missing_non_base[:20])
        )

    syms_text = original_syms.rstrip() + "\n"
    if missing_base:
        syms_text += "\nBase {\n    global:\n"
        for name in missing_base:
            syms_text += f"  {name};\n"
        syms_text += "};\n"
    SYMS.write_text(ensure_local_wildcard(syms_text), encoding="utf-8")

    version = parse_version(ORIGINAL / "libxml-2.0.pc")
    triplet = subprocess.check_output(["gcc", "-print-multiarch"], text=True).strip()

    LAYOUTS.write_text(
        json.dumps(compile_layout_probe(ORIGINAL, None), indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    ENUMS.write_text(
        json.dumps(compile_enum_probe(ORIGINAL), indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    PKGCONFIG.write_text(derive_pkgconfig_output(triplet), encoding="utf-8")
    XML2_CONFIG.write_text(derive_xml2_config_output(triplet), encoding="utf-8")
    XML2CONF.write_text(
        normalize_xml2conf((ORIGINAL / "xml2Conf.sh").read_text(encoding="utf-8"), triplet),
        encoding="utf-8",
    )
    SONAME.write_text(parse_soname(ORIGINAL / ".libs" / "libxml2.so.2.9.14"), encoding="utf-8")
    XMLLINT_HELP.write_text(
        normalize_help(run_capture([str(ORIGINAL / ".libs" / "xmllint"), "--help"])),
        encoding="utf-8",
    )
    XMLCATALOG_HELP.write_text(
        normalize_help(run_capture([str(ORIGINAL / ".libs" / "xmlcatalog"), "--help"])),
        encoding="utf-8",
    )
    PACKAGE_FILES.write_text(package_file_manifest(triplet, version), encoding="utf-8")


def parse_objdump_exports(path: Path) -> dict[str, str]:
    exports: dict[str, str] = {}
    output = subprocess.check_output(["objdump", "-T", str(path)], text=True)
    pattern = re.compile(
        r"^\S+\s+g\s+\S+\s+\S+\s+\S+\s+(\S+)\s+([A-Za-z_][A-Za-z0-9_]*)$"
    )
    for line in output.splitlines():
        match = pattern.match(line.strip())
        if not match:
            continue
        version, name = match.groups()
        if name.startswith("LIBXML2_") or name == "Base":
            continue
        exports[name] = version
    return exports


def parse_debian_symbols(path: Path) -> dict[str, str]:
    result: dict[str, str] = {}
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or line.startswith("*") or line.startswith("libxml2.so.2"):
            continue
        if line.startswith("("):
            line = line.split(")", 1)[1].strip()
        symbol = line.split()[0]
        if "@" not in symbol:
            continue
        name, version = symbol.split("@", 1)
        result[name] = version
    return result


def ensure_local_wildcard(text: str) -> str:
    if re.search(r"^\s*local:\s*$", text, re.M):
        return text

    lines = text.rstrip().splitlines()
    for index in range(len(lines) - 1, -1, -1):
        stripped = lines[index].strip()
        if stripped == "};" or stripped.startswith("} LIBXML2_"):
            lines[index:index] = ["    local:", "      *;"]
            return "\n".join(lines) + "\n"
    raise SystemExit("failed to locate a final version block terminator in safe/abi/libxml2.syms")


def parse_version(path: Path) -> str:
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.startswith("Version:"):
            return line.split(":", 1)[1].strip()
    raise SystemExit("failed to locate version in libxml-2.0.pc")


def parse_pc_fields(path: Path) -> dict[str, str]:
    variables: dict[str, str] = {}
    fields: dict[str, str] = {}

    def expand(value: str) -> str:
        previous = None
        while previous != value:
            previous = value
            value = re.sub(r"\$\{([^}]+)\}", lambda match: variables.get(match.group(1), match.group(0)), value)
        return value

    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", line):
            name, value = line.split("=", 1)
            variables[name] = expand(value.strip())
        elif ":" in line:
            name, value = line.split(":", 1)
            fields[name.strip()] = expand(value.strip())

    return fields


def normalize_command_output(text: str, triplet: str) -> str:
    normalized = text.replace("/usr/local", "/usr").replace(f"/lib/{triplet}", "/lib")
    tokens = [
        token
        for token in shlex.split(normalized)
        if token not in {f"-L/usr/lib/{triplet}", "-L/usr/lib"}
    ]
    return (" ".join(tokens).strip() + "\n") if tokens else "\n"


def derive_pkgconfig_output(triplet: str) -> str:
    fields = parse_pc_fields(ORIGINAL / "libxml-2.0.pc")
    return normalize_command_output(f"{fields.get('Cflags', '')} {fields.get('Libs', '')}", triplet)


def derive_xml2_config_output(triplet: str) -> str:
    output = subprocess.check_output([str(ORIGINAL / "xml2-config"), "--cflags", "--libs"], text=True)
    return normalize_command_output(output, triplet)


def compile_layout_probe(original_root: Path, stage_root: Path | None) -> dict[str, object]:
    with tempfile.TemporaryDirectory(prefix="libxml-layout-") as temp_dir:
        temp = Path(temp_dir)
        binary = temp / "layout-probe"
        include_dirs = [original_root, original_root / "include"]
        if stage_root is not None:
            include_dirs = [stage_root / "usr" / "include" / "libxml2"]
        command = ["cc", "-DHAVE_CONFIG_H"]
        if stage_root is None:
            command.extend([f"-I{original_root}", f"-I{original_root / 'include'}"])
        else:
            command.extend([f"-I{stage_root / 'usr' / 'include' / 'libxml2'}"])
        command.extend([str(SAFE / "tests" / "abi" / "layout_probe.c"), "-o", str(binary)])
        subprocess.check_call(command)
        return json.loads(subprocess.check_output([str(binary)], text=True))


def compile_enum_probe(original_root: Path) -> dict[str, object]:
    source = r"""
#include <stdio.h>
#include <libxml/parser.h>
#include <libxml/tree.h>
#include <libxml/xmlerror.h>
#include <libxml/xmlreader.h>
#include <libxml/xpath.h>
#include <libxml/xmlversion.h>

int main(void) {
    printf("{\n");
    printf("  \"macros\": {\n");
    printf("    \"LIBXML_VERSION\": %d,\n", LIBXML_VERSION);
    printf("    \"LIBXML_VERSION_STRING\": \"%s\",\n", LIBXML_DOTTED_VERSION);
#ifdef LIBXML_THREAD_ENABLED
    printf("    \"LIBXML_THREAD_ENABLED\": 1,\n");
#else
    printf("    \"LIBXML_THREAD_ENABLED\": 0,\n");
#endif
#ifdef LIBXML_OUTPUT_ENABLED
    printf("    \"LIBXML_OUTPUT_ENABLED\": 1,\n");
#else
    printf("    \"LIBXML_OUTPUT_ENABLED\": 0,\n");
#endif
#ifdef LIBXML_XPATH_ENABLED
    printf("    \"LIBXML_XPATH_ENABLED\": 1\n");
#else
    printf("    \"LIBXML_XPATH_ENABLED\": 0\n");
#endif
    printf("  },\n");
    printf("  \"enums\": {\n");
    printf("    \"XML_ELEMENT_NODE\": %d,\n", XML_ELEMENT_NODE);
    printf("    \"XML_ATTRIBUTE_NODE\": %d,\n", XML_ATTRIBUTE_NODE);
    printf("    \"XML_TEXT_NODE\": %d,\n", XML_TEXT_NODE);
    printf("    \"XML_DOCUMENT_NODE\": %d,\n", XML_DOCUMENT_NODE);
    printf("    \"XML_PARSE_RECOVER\": %d,\n", XML_PARSE_RECOVER);
    printf("    \"XML_PARSE_NOENT\": %d,\n", XML_PARSE_NOENT);
    printf("    \"XML_PARSE_DTDLOAD\": %d,\n", XML_PARSE_DTDLOAD);
    printf("    \"XML_PARSE_NONET\": %d,\n", XML_PARSE_NONET);
    printf("    \"XML_PARSE_NOBLANKS\": %d,\n", XML_PARSE_NOBLANKS);
    printf("    \"XML_PARSE_HUGE\": %d,\n", XML_PARSE_HUGE);
    printf("    \"XML_ERR_WARNING\": %d,\n", XML_ERR_WARNING);
    printf("    \"XML_ERR_ERROR\": %d,\n", XML_ERR_ERROR);
    printf("    \"XML_ERR_FATAL\": %d,\n", XML_ERR_FATAL);
    printf("    \"XML_READER_TYPE_ELEMENT\": %d,\n", XML_READER_TYPE_ELEMENT);
    printf("    \"XML_READER_TYPE_TEXT\": %d,\n", XML_READER_TYPE_TEXT);
    printf("    \"XPATH_UNDEFINED\": %d,\n", XPATH_UNDEFINED);
    printf("    \"XPATH_NODESET\": %d,\n", XPATH_NODESET);
    printf("    \"XPATH_BOOLEAN\": %d,\n", XPATH_BOOLEAN);
    printf("    \"XPATH_NUMBER\": %d,\n", XPATH_NUMBER);
    printf("    \"XPATH_STRING\": %d\n", XPATH_STRING);
    printf("  }\n");
    printf("}\n");
    return 0;
}
"""

    with tempfile.TemporaryDirectory(prefix="libxml-enums-") as temp_dir:
        temp = Path(temp_dir)
        source_path = temp / "enum-probe.c"
        binary = temp / "enum-probe"
        source_path.write_text(source, encoding="utf-8")
        subprocess.check_call(
            [
                "cc",
                "-DHAVE_CONFIG_H",
                f"-I{original_root}",
                f"-I{original_root / 'include'}",
                str(source_path),
                "-o",
                str(binary),
            ]
        )
        return json.loads(subprocess.check_output([str(binary)], text=True))


def normalize_help(text: str) -> str:
    return "\n".join(line.rstrip() for line in text.replace("\r\n", "\n").splitlines()) + "\n"


def normalize_xml2conf(text: str, triplet: str) -> str:
    normalized = text.replace("/usr/local", "/usr").replace(f"/lib/{triplet}", "/lib")
    return normalize_help(normalized)


def parse_soname(path: Path) -> str:
    output = subprocess.check_output(["readelf", "-d", str(path)], text=True)
    match = re.search(r"\(SONAME\).*Library soname: \[(.+)\]", output)
    if not match:
        raise SystemExit(f"failed to locate SONAME in {path}")
    return match.group(1) + "\n"


def run_capture(argv: list[str]) -> str:
    process = subprocess.run(argv, check=False, text=True, capture_output=True)
    return process.stdout + process.stderr


def package_file_manifest(triplet: str, version: str) -> str:
    sections = [
        ("libxml2", derive_package_entries("libxml2", triplet, version)),
        ("libxml2-dev", derive_package_entries("libxml2-dev", triplet, version)),
        ("libxml2-utils", derive_package_entries("libxml2-utils", triplet, version)),
        ("python3-libxml2", derive_package_entries("python3-libxml2", triplet, version)),
    ]

    lines = [
        "# Canonical package-file baseline for the phase-1 replacement package set.",
        "# Derived from original/debian/*.install and *.manpages plus the materialized original build oracles.",
        "",
    ]
    for name, entries in sections:
        lines.append(f"[{name}]")
        lines.extend(entries)
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def derive_package_entries(package: str, triplet: str, version: str) -> list[str]:
    entries: list[str] = []
    install_manifest = ORIGINAL / "debian" / f"{package}.install"
    for line in read_manifest_lines(install_manifest):
        entries.extend(resolve_install_entry(package, line, triplet, version))
    manpages = ORIGINAL / "debian" / f"{package}.manpages"
    if manpages.exists():
        for line in read_manifest_lines(manpages):
            entries.extend(resolve_manpage_entry(line))
    return sorted(dict.fromkeys(entries))


def read_manifest_lines(path: Path) -> list[str]:
    return [
        line.strip()
        for line in path.read_text(encoding="utf-8").splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    ]


def resolve_install_entry(package: str, line: str, triplet: str, version: str) -> list[str]:
    if package == "libxml2" and line == "usr/lib/*/libxml2.so.*":
        shared_names = sorted(
            path.name
            for path in (ORIGINAL / ".libs").iterdir()
            if re.fullmatch(r"libxml2\.so\.\d+(?:\.\d+)*", path.name)
        )
        return ["/usr/lib", f"/usr/lib/{triplet}"] + [f"/usr/lib/{triplet}/{name}" for name in shared_names]

    if package == "libxml2-dev" and line == "usr/bin/xml2-config":
        return ["/usr/bin/xml2-config"]
    if package == "libxml2-dev" and line == "usr/include/libxml2":
        headers = [
            f"/usr/include/libxml2/libxml/{header.name}"
            for header in sorted((SAFE / "include" / "libxml").glob("*.h"))
        ]
        return ["/usr/include/libxml2", "/usr/include/libxml2/config.h", "/usr/include/libxml2/libxml"] + headers
    if package == "libxml2-dev" and line == "usr/lib/*/libxml2.a":
        return ["/usr/lib", f"/usr/lib/{triplet}", f"/usr/lib/{triplet}/libxml2.a"]
    if package == "libxml2-dev" and line == "usr/lib/*/libxml2.so":
        return ["/usr/lib", f"/usr/lib/{triplet}", f"/usr/lib/{triplet}/libxml2.so"]
    if package == "libxml2-dev" and line == "usr/lib/*/pkgconfig":
        return [f"/usr/lib/{triplet}/pkgconfig", f"/usr/lib/{triplet}/pkgconfig/libxml-2.0.pc"]
    if package == "libxml2-dev" and line == "usr/lib/*/xml2Conf.sh":
        return [f"/usr/lib/{triplet}/xml2Conf.sh"]
    if package == "libxml2-dev" and line == "usr/share/aclocal":
        return ["/usr/share/aclocal", "/usr/share/aclocal/libxml2.m4"]

    if package == "libxml2-utils" and line == "usr/bin/xmlcatalog":
        return ["/usr/bin/xmlcatalog"]
    if package == "libxml2-utils" and line == "usr/bin/xmllint":
        return ["/usr/bin/xmllint"]

    if package == "python3-libxml2" and line == "usr/lib/python3*/*-packages/*.py*":
        python_dir = python_install_dir_from_manifest(line)
        return [python_dir] + [f"{python_dir}/{name}" for name in parse_makefile_words(ORIGINAL / "python" / "Makefile.am", "dist_python_DATA")]
    if package == "python3-libxml2" and line == "usr/lib/python3*/*-packages/*.so":
        python_dir = python_install_dir_from_manifest(line)
        module_names = [Path(name).stem + ".so" for name in parse_makefile_words(ORIGINAL / "python" / "Makefile.am", "python_LTLIBRARIES")]
        return [python_dir] + [f"{python_dir}/{name}" for name in module_names]

    raise SystemExit(f"unhandled install manifest entry {package}: {line}")


def resolve_manpage_entry(line: str) -> list[str]:
    path = "/" + line
    if not path.endswith(".gz"):
        path += ".gz"
    return [str(Path(path).parent), path]


def python_install_dir_from_manifest(pattern: str) -> str:
    parent = Path(pattern).parent.as_posix()
    parent = parent.replace("python3*", "python3").replace("*-packages", "dist-packages")
    return "/" + parent.lstrip("/")


def parse_makefile_words(path: Path, variable: str) -> list[str]:
    lines = path.read_text(encoding="utf-8").splitlines()
    chunks: list[str] = []
    collecting = False
    for raw_line in lines:
        line = raw_line.split("#", 1)[0].rstrip()
        if not collecting:
            match = re.match(rf"^{re.escape(variable)}\s*=\s*(.*)$", line)
            if not match:
                continue
            chunk = match.group(1).strip()
            collecting = True
        else:
            chunk = line.strip()
        if chunk.endswith("\\"):
            chunks.append(chunk[:-1].strip())
            continue
        chunks.append(chunk)
        break
    return [word for word in " ".join(chunks).split() if word]


if __name__ == "__main__":
    main()
