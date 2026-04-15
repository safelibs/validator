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
    fprintf(stderr, "The libuv test suite cannot be run as root.\n");
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
    fprintf(stderr, "Too many arguments.\n");
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
    printf("hello world\n");
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
    buffer[sizeof(buffer) - 1] = '\0';
    fputs(buffer, stdout);
    return 1;
  }

  if (strcmp(argv[1], "spawn_helper4") == 0) {
    notify_parent_process();
    for (;;)
      uv_sleep(10000);
  }

  if (strcmp(argv[1], "spawn_helper5") == 0) {
    const char out[] = "fourth stdio!\n";
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

    r = fprintf(stdout, "hello world\n");
    ASSERT_GT(r, 0);

    r = fprintf(stderr, "hello errworld\n");
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
