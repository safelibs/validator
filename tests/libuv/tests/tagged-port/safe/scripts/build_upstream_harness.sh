#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: $0 --stage <prefix> --build <dir>" >&2
  exit 64
}

stage_prefix=""
build_dir=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --stage)
      [[ $# -ge 2 ]] || usage
      stage_prefix="$2"
      shift 2
      ;;
    --build)
      [[ $# -ge 2 ]] || usage
      build_dir="$2"
      shift 2
      ;;
    *)
      usage
      ;;
  esac
done

[[ -n "${stage_prefix}" && -n "${build_dir}" ]] || usage

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
safe_root="$(cd "${script_dir}/.." && pwd)"
repo_root="$(cd "${safe_root}/.." && pwd)"
generated_dir="${build_dir}/generated"
template_dir="${safe_root}/tests/harness"

mkdir -p "${generated_dir}"

if [[ -z "${LIBUV_SAFE_NO_PYTHON:-}" ]] && command -v python3 >/dev/null 2>&1; then
python3 - "${repo_root}" "${generated_dir}" <<'PY'
import subprocess
import sys
import re
from pathlib import Path

repo_root = Path(sys.argv[1])
generated_dir = Path(sys.argv[2])
original_test_list = repo_root / "original/test/test-list.h"

selected_tests = [
    "version",
    "loop_new_delete",
    "print_handles",
    "handle_type_name",
    "req_type_name",
    "loop_configure",
    "loop_alive",
    "loop_close",
    "loop_stop",
    "run_once",
    "run_nowait",
    "once",
    "async",
    "thread_create",
    "thread_local_storage",
    "thread_stack_size",
    "thread_stack_size_explicit",
    "threadpool_queue_work_simple",
    "threadpool_queue_work_einval",
    "threadpool_multiple_event_loops",
    "random_async",
    "random_sync",
    "barrier_1",
    "barrier_2",
    "barrier_3",
    "barrier_serial_thread",
    "barrier_serial_thread_single",
    "condvar_1",
    "condvar_2",
    "condvar_3",
    "condvar_4",
    "condvar_5",
    "thread_mutex",
    "thread_mutex_recursive",
    "thread_rwlock",
    "thread_rwlock_trylock",
    "semaphore_1",
    "semaphore_2",
    "semaphore_3",
    "metrics_idle_time",
    "metrics_idle_time_thread",
    "metrics_idle_time_zero",
    "metrics_info_check",
    "metrics_pool_events",
    "threadpool_cancel_work",
    "threadpool_cancel_random",
    "threadpool_cancel_single",
    "threadpool_cancel_when_busy",
    "fork_timer",
    "fork_socketpair",
    "fork_socketpair_started",
    "fork_signal_to_child",
    "fork_signal_to_child_closed",
    "fork_close_signal_in_child",
    "fork_threadpool_queue_work_simple",
    "poll_duplex",
    "poll_unidirectional",
    "poll_bad_fdtype",
    "poll_nested_epoll",
    "signal_multiple_loops",
    "signal_pending_on_close",
    "tcp_ping_pong",
    "tcp_ping_pong_vec",
    "pipe_ping_pong",
    "pipe_ping_pong_vec",
    "shutdown_close_pipe",
    "shutdown_close_tcp",
    "shutdown_eof",
    "shutdown_simultaneous",
    "shutdown_twice",
    "multiple_listen",
    "connection_fail",
    "tcp_close_reset_client",
    "tcp_close_reset_client_after_shutdown",
    "tcp_close_reset_accepted",
    "tcp_close_reset_accepted_after_shutdown",
    "pipe_connect_bad_name",
    "pipe_connect_close_multiple",
    "pipe_connect_multiple",
    "pipe_connect_on_prepare",
    "pipe_getsockname",
    "pipe_pending_instances",
    "pipe_sendmsg",
    "pipe_server_close",
    "pipe_set_chmod",
    "pipe_set_non_blocking",
    "tty",
    "tty_file",
    "tty_pty",
    "udp_bind",
    "udp_connect",
    "udp_connect6",
    "udp_open",
    "udp_open_twice",
    "udp_open_bound",
    "udp_open_connect",
    "udp_send_and_recv",
    "udp_send_immediate",
    "udp_send_unreachable",
    "udp_try_send",
    "udp_recv_in_a_row",
    "udp_options",
    "udp_options6",
    "udp_no_autobind",
    "udp_mmsg",
    "udp_multicast_join",
    "udp_multicast_join6",
    "udp_multicast_interface",
    "udp_multicast_interface6",
    "udp_multicast_ttl",
    "udp_dual_stack",
    "udp_ipv6_only",
    "udp_dgram_too_big",
    "ipc_send_recv_pipe",
    "ipc_send_recv_pipe_inprocess",
    "ipc_send_recv_tcp",
    "ipc_send_recv_tcp_inprocess",
    "ipc_tcp_connection",
    "ipc_listen_before_write",
    "ipc_listen_after_write",
    "ipc_send_zero",
    "ipc_heavy_traffic_deadlock_bug",
    "dlerror",
    "kill",
    "kill_invalid_signum",
    "process_title",
    "process_title_threadsafe",
    "spawn_stdout",
    "spawn_stdin",
    "spawn_exit_code",
    "spawn_and_kill",
    "spawn_and_kill_with_std",
    "spawn_and_ping",
    "spawn_detached",
    "spawn_auto_unref",
    "spawn_empty_env",
    "spawn_preserve_env",
    "spawn_setuid_setgid",
    "spawn_setuid_fails",
    "spawn_setgid_fails",
    "fs_file_noent",
    "fs_file_nametoolong",
    "fs_file_loop",
    "fs_file_async",
    "fs_file_sync",
    "fs_async_dir",
    "fs_async_sendfile",
    "fs_async_sendfile_nodata",
    "fs_copyfile",
    "fs_mkdtemp",
    "fs_mkstemp",
    "fs_fstat",
    "fs_access",
    "fs_chmod",
    "fs_chown",
    "fs_link",
    "fs_readlink",
    "fs_realpath",
    "fs_symlink",
    "fs_utime",
    "fs_futime",
    "fs_lutime",
    "fs_stat_missing_path",
    "fs_scandir_empty_dir",
    "fs_scandir_non_existent_dir",
    "fs_scandir_file",
    "fs_scandir_early_exit",
    "fs_open_dir",
    "fs_read_dir",
    "fs_read_bufs",
    "fs_read_file_eof",
    "fs_write_multiple_bufs",
    "fs_write_alotof_bufs",
    "fs_write_alotof_bufs_with_offset",
    "fs_partial_read",
    "fs_partial_write",
    "fs_read_write_null_arguments",
    "fs_file_pos_after_op_with_offset",
    "fs_file_open_append",
    "fs_null_req",
    "fs_rename_to_existing_file",
    "fs_statfs",
    "fs_get_system_error",
    "fs_stat_batch_multiple",
    "getters_setters",
    "fs_poll",
    "fs_poll_getpath",
    "fs_poll_close_request",
    "fs_poll_close_request_multi_start_stop",
    "fs_poll_close_request_multi_stop_start",
    "fs_poll_close_request_stop_when_active",
    "fs_event_watch_dir",
    "fs_event_watch_dir_recursive",
    "fs_event_watch_file",
    "fs_event_watch_file_exact_path",
    "fs_event_watch_file_current_dir",
    "fs_event_watch_file_twice",
    "fs_event_no_callback_after_close",
    "fs_event_no_callback_on_close",
    "fs_event_immediate_close",
    "fs_event_close_with_pending_event",
    "fs_event_close_with_pending_delete_event",
    "fs_event_close_in_callback",
    "fs_event_start_and_close",
    "fs_event_error_reporting",
    "fs_event_getpath",
    "fs_event_watch_invalid_path",
    "fs_event_stop_in_cb",
    "getaddrinfo_fail",
    "getaddrinfo_fail_sync",
    "getaddrinfo_basic",
    "getaddrinfo_basic_sync",
    "getaddrinfo_concurrent",
    "getnameinfo_basic_ip4",
    "getnameinfo_basic_ip4_sync",
    "getnameinfo_basic_ip6",
    "gethostname",
    "idna_toascii",
    "utf8_decode1",
    "utf8_decode1_overrun",
    "ip4_addr",
    "ip6_pton",
    "ip6_addr_link_local",
    "ip_name",
    "get_currentexe",
    "get_loadavg",
    "get_memory",
    "get_passwd",
    "get_group",
    "homedir",
    "tmpdir",
    "cwd_and_chdir",
    "env_vars",
    "process_priority",
    "platform_output",
    "uname",
    "hrtime",
    "gettimeofday",
    "clock_gettime",
]

expected_delta = {
    "loop_new_delete",
    "once",
    "print_handles",
    "udp_send_queue_getters",
    "version",
}

def listed(binary: Path) -> list[str]:
    return subprocess.check_output([str(binary), "--list"], text=True).splitlines()

review_tests = listed(repo_root / "original/build-checker-review/uv_run_tests")
review_tests_a = listed(repo_root / "original/build-checker-review/uv_run_tests_a")
review_bench = listed(repo_root / "original/build-checker-review/uv_run_benchmarks_a")
old_tests = listed(repo_root / "original/build-checker/uv_run_tests")
old_tests_a = listed(repo_root / "original/build-checker/uv_run_tests_a")
old_bench = listed(repo_root / "original/build-checker/uv_run_benchmarks_a")

if (len(review_tests), len(review_tests_a), len(review_bench)) != (440, 440, 55):
    raise SystemExit("unexpected original/build-checker-review inventory counts")

if (len(old_tests), len(old_tests_a), len(old_bench)) != (435, 435, 55):
    raise SystemExit("unexpected original/build-checker inventory counts")

if set(review_tests) - set(old_tests) != expected_delta or set(old_tests) - set(review_tests):
    raise SystemExit("shared test inventory delta no longer matches the checked-in contract")

if set(review_tests_a) - set(old_tests_a) != expected_delta or set(old_tests_a) - set(review_tests_a):
    raise SystemExit("static test inventory delta no longer matches the checked-in contract")

if set(review_bench) != set(old_bench):
    raise SystemExit("benchmark inventory changed unexpectedly between baseline trees")

test_list_text = original_test_list.read_text()
lines = test_list_text.splitlines()
decl_re = re.compile(r"^(TEST_DECLARE|HELPER_DECLARE)\s+\(([^)]+)\)")
task_start = lines.index("TASK_LIST_START")
task_end = lines.index("TASK_LIST_END")

declaration_lines = {}
for line in lines[:task_start]:
    match = decl_re.match(line.strip())
    if match is not None:
        declaration_lines[match.group(2)] = line.strip()

missing = [name for name in selected_tests if name not in declaration_lines]
if missing:
    raise SystemExit(f"missing declarations in current test-list.h: {', '.join(missing)}")

selected_set = set(selected_tests)
helper_names = set()
task_lines = []

for raw_line in lines[task_start + 1:task_end]:
    line = raw_line.strip()
    entry_match = re.match(r"^(TEST_ENTRY|TEST_ENTRY_CUSTOM)\s+\(([^),]+)", line)
    helper_match = re.match(r"^TEST_HELPER\s+\(([^),]+),\s*([^)]+)\)", line)

    if entry_match is not None:
        test_name = entry_match.group(2).strip()
        if test_name in selected_set:
            task_lines.append(raw_line.rstrip())
        continue

    if helper_match is not None:
        test_name = helper_match.group(1).strip()
        helper_name = helper_match.group(2).strip()
        if test_name in selected_set:
            task_lines.append(raw_line.rstrip())
            helper_names.add(helper_name)

phase_declarations = []
for raw_line in lines[:task_start]:
    line = raw_line.strip()
    match = decl_re.match(line)
    if match is None:
        continue
    name = match.group(2)
    if name in selected_set or name in helper_names:
        phase_declarations.append(line)

phase_test_list = "\n".join(
    [
        *phase_declarations,
        "TASK_LIST_START",
        *task_lines,
        "TASK_LIST_END",
        "",
    ]
)

run_tests_c = """\
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef _WIN32
# include <io.h>
# define read _read
#else
# include <unistd.h>
#endif

#include "uv.h"
#include "runner.h"
#include "task.h"
#include "phase-test-list.h"

int ipc_helper(int listen_after_write);
int ipc_helper_heavy_traffic_deadlock_bug(void);
int ipc_helper_tcp_connection(void);
int ipc_send_recv_helper(void);
int ipc_helper_bind_twice(void);
int ipc_helper_send_zero(void);
void spawn_stdin_stdout(void);
void process_title_big_argv(void);
int spawn_tcp_server_helper(void);

static int maybe_run_test(int argc, char** argv);

int main(int argc, char** argv) {
#ifndef _WIN32
  if (0 == geteuid() && NULL == getenv("UV_RUN_AS_ROOT")) {
    fprintf(stderr, "The libuv test suite cannot be run as root.\\n");
    return EXIT_FAILURE;
  }
#endif

  platform_init(argc, argv);
  argv = uv_setup_args(argc, argv);

  switch (argc) {
  case 1:
    return run_tests(0);
  case 2:
    return maybe_run_test(argc, argv);
  case 3:
    return run_test_part(argv[1], argv[2]);
  case 4:
    return maybe_run_test(argc, argv);
  default:
    fprintf(stderr, "Too many arguments.\\n");
    fflush(stderr);
    return EXIT_FAILURE;
  }
}

static int maybe_run_test(int argc, char** argv) {
  (void) argc;

  if (strcmp(argv[1], "--list") == 0) {
    print_tests(stdout);
    return 0;
  }

  if (strcmp(argv[1], "ipc_helper_listen_before_write") == 0) {
    return ipc_helper(0);
  }

  if (strcmp(argv[1], "ipc_helper_listen_after_write") == 0) {
    return ipc_helper(1);
  }

  if (strcmp(argv[1], "ipc_helper_heavy_traffic_deadlock_bug") == 0) {
    return ipc_helper_heavy_traffic_deadlock_bug();
  }

  if (strcmp(argv[1], "ipc_send_recv_helper") == 0) {
    return ipc_send_recv_helper();
  }

  if (strcmp(argv[1], "ipc_helper_tcp_connection") == 0) {
    return ipc_helper_tcp_connection();
  }

  if (strcmp(argv[1], "ipc_helper_bind_twice") == 0) {
    return ipc_helper_bind_twice();
  }

  if (strcmp(argv[1], "ipc_helper_send_zero") == 0) {
    return ipc_helper_send_zero();
  }

  if (strcmp(argv[1], "spawn_helper1") == 0) {
    notify_parent_process();
    return 1;
  }

  if (strcmp(argv[1], "spawn_helper2") == 0) {
    notify_parent_process();
    printf("hello world\\n");
    return 1;
  }

  if (strcmp(argv[1], "spawn_tcp_server_helper") == 0) {
    notify_parent_process();
    return spawn_tcp_server_helper();
  }

  if (strcmp(argv[1], "spawn_helper3") == 0) {
    char buffer[256];
    notify_parent_process();
    ASSERT_PTR_EQ(buffer, fgets(buffer, sizeof(buffer) - 1, stdin));
    buffer[sizeof(buffer) - 1] = '\\0';
    fputs(buffer, stdout);
    return 1;
  }

  if (strcmp(argv[1], "spawn_helper4") == 0) {
    notify_parent_process();
    for (;;)
      uv_sleep(10000);
  }

  if (strcmp(argv[1], "spawn_helper5") == 0) {
    const char out[] = "fourth stdio!\\n";
    notify_parent_process();
    {
      ssize_t r;
      do
        r = write(3, out, sizeof(out) - 1);
      while (r == -1 && errno == EINTR);

      fsync(3);
    }
    return 1;
  }

  if (strcmp(argv[1], "spawn_helper6") == 0) {
    int r;

    notify_parent_process();

    r = fprintf(stdout, "hello world\\n");
    ASSERT_GT(r, 0);

    r = fprintf(stderr, "hello errworld\\n");
    ASSERT_GT(r, 0);

    return 1;
  }

  if (strcmp(argv[1], "spawn_helper7") == 0) {
    int r;
    char* test;

    notify_parent_process();

    test = getenv("ENV_TEST");
    ASSERT_NOT_NULL(test);

    r = fprintf(stdout, "%s", test);
    ASSERT_GT(r, 0);

    return 1;
  }

  if (strcmp(argv[1], "spawn_helper8") == 0) {
    uv_os_fd_t closed_fd;
    uv_os_fd_t open_fd;

    notify_parent_process();
    ASSERT_EQ(sizeof(closed_fd), read(0, &closed_fd, sizeof(closed_fd)));
    ASSERT_EQ(sizeof(open_fd), read(0, &open_fd, sizeof(open_fd)));
    ASSERT_GT(open_fd, 2);
    ASSERT_GT(closed_fd, 2);
    ASSERT_EQ(-1, write(closed_fd, "x", 1));
    return 1;
  }

  if (strcmp(argv[1], "spawn_helper9") == 0) {
    notify_parent_process();
    spawn_stdin_stdout();
    return 1;
  }

#ifndef _WIN32
  if (strcmp(argv[1], "spawn_helper_setuid_setgid") == 0) {
    uv_uid_t uid = atoi(argv[2]);
    uv_gid_t gid = atoi(argv[3]);

    ASSERT_EQ(uid, getuid());
    ASSERT_EQ(gid, getgid());
    notify_parent_process();

    return 1;
  }
#endif

  if (strcmp(argv[1], "process_title_big_argv_helper") == 0) {
    notify_parent_process();
    process_title_big_argv();
    return 0;
  }

  return run_test(argv[1], 0, 1);
}
"""

benchmark_main_c = """\
int run_benchmark_sizes(void);
int main(void) {
  return run_benchmark_sizes();
}
"""

generated_dir.mkdir(parents=True, exist_ok=True)
(generated_dir / "phase-test-list.h").write_text(phase_test_list)
(generated_dir / "uv-safe-run-tests.c").write_text(run_tests_c)
(generated_dir / "benchmark-sizes-main.c").write_text(benchmark_main_c)
PY
else
  cp "${template_dir}/phase-test-list.h" "${generated_dir}/phase-test-list.h"
  cp "${template_dir}/uv-safe-run-tests.c" "${generated_dir}/uv-safe-run-tests.c"
  cat > "${generated_dir}/benchmark-sizes-main.c" <<'EOF'
int run_benchmark_sizes(void);
int main(void) {
  return run_benchmark_sizes();
}
EOF
fi

cmake -S "${safe_root}/tests/harness" \
  -B "${build_dir}" \
  -DSTAGE_PREFIX="${stage_prefix}" \
  -DGENERATED_DIR="${generated_dir}"
cmake --build "${build_dir}"
