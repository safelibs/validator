#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
safe_root="$(cd "${script_dir}/.." && pwd)"
repo_root="$(cd "${safe_root}/.." && pwd)"
tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

export SAFE_ROOT="${safe_root}"
export REPO_ROOT="${repo_root}"
export TMPDIR_PATH="${tmpdir}"

python3 - <<'PY'
import json
import os
import shlex
from pathlib import Path

repo_root = Path(os.environ["REPO_ROOT"])
safe_root = Path(os.environ["SAFE_ROOT"])
tmpdir = Path(os.environ["TMPDIR_PATH"])
compile_commands = json.loads((repo_root / "original/build-checker/compile_commands.json").read_text())

shared_entry = None
for entry in compile_commands:
    if "CMakeFiles/uv.dir/" in entry["command"]:
        shared_entry = entry
        break

if shared_entry is None:
    raise SystemExit("unable to locate a shared-library compile command in compile_commands.json")

command = shlex.split(shared_entry["command"])
clang_args = []
it = iter(command[1:])
for token in it:
    if token == "-o":
        break
    if token == "-c":
        next(it, None)
        continue
    if token.startswith("-D") or token.startswith("-I"):
        clang_args.append(token)

safe_include = str((safe_root / "include").resolve())
original_include = str((repo_root / "original/include").resolve())
clang_args = [token.replace(original_include, safe_include) for token in clang_args]

exports = [
    line.strip()
    for line in os.popen(
        f"nm -D --defined-only {shlex.quote(str(repo_root / 'original/build-checker/libuv.so.1.0.0'))} "
        "| awk '{print $3}' | sort"
    ).read().splitlines()
    if line.strip()
]

config = {
    "clang_args": clang_args,
    "exports": exports,
    "manual_impls": [
        "uv_backend_fd",
        "uv_backend_timeout",
        "uv_buf_init",
        "uv_cpumask_size",
        "uv_fs_get_path",
        "uv_fs_get_ptr",
        "uv_fs_get_result",
        "uv_fs_get_statbuf",
        "uv_fs_get_system_error",
        "uv_fs_get_type",
        "uv_handle_get_data",
        "uv_handle_get_loop",
        "uv_handle_get_type",
        "uv_handle_set_data",
        "uv_handle_size",
        "uv_handle_type_name",
        "uv_has_ref",
        "uv_is_active",
        "uv_is_closing",
        "uv_is_readable",
        "uv_is_writable",
        "uv_loop_alive",
        "uv_loop_get_data",
        "uv_loop_set_data",
        "uv_loop_size",
        "uv_now",
        "uv_pipe_pending_count",
        "uv_process_get_pid",
        "uv_req_get_data",
        "uv_req_get_type",
        "uv_req_set_data",
        "uv_req_size",
        "uv_req_type_name",
        "uv_setup_args",
        "uv_stream_get_write_queue_size",
        "uv_thread_equal",
        "uv_thread_getcpu",
        "uv_timer_get_due_in",
        "uv_timer_get_repeat",
        "uv_timer_set_repeat",
        "uv_udp_get_send_queue_count",
        "uv_udp_get_send_queue_size",
        "uv_udp_using_recvmmsg",
        "uv_version",
        "uv_version_string",
    ],
    "int_zero_impls": [],
    "int_neg_one_impls": [],
}
(tmpdir / "config.json").write_text(json.dumps(config, indent=2) + "\n")
PY

mkdir -p "${tmpdir}/bindgen-gen/src"

python3 - <<'PY'
import json
import os
import textwrap
from pathlib import Path

safe_root = Path(os.environ["SAFE_ROOT"])
tmpdir = Path(os.environ["TMPDIR_PATH"])
config = json.loads((tmpdir / "config.json").read_text())
clang_args_literal = json.dumps(config["clang_args"])

manifest = textwrap.dedent(
    """
    [package]
    name = "uv-bindgen-gen"
    version = "0.1.0"
    edition = "2021"

    [dependencies]
    bindgen = "0.72"
    """
).strip() + "\n"

main_rs = textwrap.dedent(
    f"""
    use std::path::PathBuf;

    fn main() {{
        let output = PathBuf::from("{(tmpdir / 'linux_x86_64.rs').as_posix()}");
        let mut builder = bindgen::Builder::default()
            .header("{(safe_root / 'include/uv.h').as_posix()}")
            .allowlist_function("uv_.*")
            .allowlist_type("uv_.*")
            .allowlist_var("UV_.*")
            .allowlist_type("sockaddr")
            .allowlist_type("sockaddr_in")
            .allowlist_type("sockaddr_in6")
            .allowlist_type("sockaddr_storage")
            .allowlist_type("addrinfo")
            .allowlist_type("socklen_t")
            .allowlist_type("fd_set")
            .allowlist_type("stat")
            .allowlist_type("timespec")
            .allowlist_type("timeval")
            .allowlist_recursively(true)
            .opaque_type("FILE")
            .opaque_type("__.*")
            .size_t_is_usize(true)
            .layout_tests(false)
            .generate_comments(true)
            .derive_default(true)
            .formatter(bindgen::Formatter::Rustfmt)
            .parse_callbacks(Box::new(bindgen::CargoCallbacks::new()));

        for arg in {clang_args_literal} {{
            builder = builder.clang_arg(arg);
        }}

        let bindings = builder.generate().expect("generate bindings");
        bindings.write_to_file(output).expect("write bindings");
    }}
    """
).strip() + "\n"

(tmpdir / "bindgen-gen/Cargo.toml").write_text(manifest)
(tmpdir / "bindgen-gen/src/main.rs").write_text(main_rs)
PY

cargo run --quiet --manifest-path "${tmpdir}/bindgen-gen/Cargo.toml"

python3 - <<'PY'
import json
import os
import re
import subprocess
from pathlib import Path

safe_root = Path(os.environ["SAFE_ROOT"])
tmpdir = Path(os.environ["TMPDIR_PATH"])
config = json.loads((tmpdir / "config.json").read_text())
bindings_path = tmpdir / "linux_x86_64.rs"
generated_path = safe_root / "src/exports/generated.rs"
final_bindings_path = safe_root / "src/abi/linux_x86_64.rs"

bindings = bindings_path.read_text()
final_bindings_path.write_text(bindings)

abi_names = set(
    re.findall(r"^pub (?:type|struct|union) ([A-Za-z_][A-Za-z0-9_]*)", bindings, re.M)
)
abi_names.update(re.findall(r"^pub const ([A-Za-z_][A-Za-z0-9_]*)", bindings, re.M))

function_pattern = re.compile(
    r'unsafe extern "C" \{\s+pub fn (uv_[A-Za-z0-9_]+)\((.*?)\)(?:\s*->\s*(.*?))?;\s+\}',
    re.S,
)
functions = {
    match.group(1): (match.group(2).strip(), (match.group(3) or "").strip())
    for match in function_pattern.finditer(bindings)
}

exports = config["exports"]
manual_impls = set(config["manual_impls"])
int_zero_impls = set(config["int_zero_impls"])
int_neg_one_impls = set(config["int_neg_one_impls"])

missing = [name for name in exports if name not in functions]
if missing:
    raise SystemExit(f"missing signatures for exported functions: {missing}")

identifier = re.compile(r"\b[A-Za-z_][A-Za-z0-9_]*\b")

def qualify_types(signature: str) -> str:
    def repl(match: re.Match[str]) -> str:
        token = match.group(0)
        start = match.start()
        prefix = signature[max(0, start - 5):start]
        if token in abi_names and prefix not in ("abi::", "::abi"):
            if signature[max(0, start - 2):start] == "::":
                return token
            return f"abi::{token}"
        return token

    return identifier.sub(repl, signature)

lines = [
    "use crate::abi::linux_x86_64 as abi;",
    "",
]

for name in exports:
    if name in manual_impls:
        continue
    raw_args, raw_ret = functions[name]
    raw_args = raw_args.replace(",\n        ...", "").replace(", ...", "").replace("...", "")
    args = qualify_types(raw_args)
    ret = qualify_types(raw_ret)

    if not ret:
        body = f'    panic!("missing manual implementation for {name}")'
    elif ret == "::std::os::raw::c_int":
        if name in int_neg_one_impls:
            body = "    -1"
        elif name in int_zero_impls:
            body = "    0"
        else:
            body = f'    panic!("missing manual implementation for {name}")'
    else:
        body = f'    panic!("missing manual implementation for {name}")'

    lines.extend(
        [
            "#[unsafe(no_mangle)]",
            "// SAFETY(ffi_callback): generated exports bridge the libuv C ABI and require a manual implementation.",
            f'pub extern "C" fn {name}({args})' + (f" -> {ret}" if ret else "") + " {",
            body,
            "}",
            "",
        ]
    )

generated_path.write_text("\n".join(lines).rstrip() + "\n")
subprocess.check_call(["rustfmt", str(final_bindings_path), str(generated_path)])
PY
