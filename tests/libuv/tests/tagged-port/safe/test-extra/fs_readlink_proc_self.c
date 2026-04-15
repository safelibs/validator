#include <uv.h>

#include <dlfcn.h>
#include <limits.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

typedef int (*uv_fs_readlink_fn)(uv_loop_t*, uv_fs_t*, const char*, uv_fs_cb);
typedef void (*uv_fs_req_cleanup_fn)(uv_fs_t*);

static int fail(const char* message) {
  fprintf(stderr, "%s\n", message);
  return 1;
}

static void* load_symbol(void* handle, const char* name) {
  void* symbol;

  dlerror();
  symbol = dlsym(handle, name);
  if (symbol == NULL)
    fprintf(stderr, "failed to resolve %s: %s\n", name, dlerror());

  return symbol;
}

int main(void) {
  const char* path = "/proc/self/exe";
  struct stat st;
  uv_fs_t req;
  char expected[PATH_MAX + 1];
  void* uv_lib;
  uv_fs_readlink_fn p_uv_fs_readlink;
  uv_fs_req_cleanup_fn p_uv_fs_req_cleanup;
  ssize_t n;
  int r;

  uv_lib = dlopen("libuv.so.1", RTLD_NOW | RTLD_GLOBAL);
  if (uv_lib == NULL)
    return fail(dlerror());

  p_uv_fs_readlink = (uv_fs_readlink_fn) load_symbol(uv_lib, "uv_fs_readlink");
  p_uv_fs_req_cleanup =
      (uv_fs_req_cleanup_fn) load_symbol(uv_lib, "uv_fs_req_cleanup");
  if (p_uv_fs_readlink == NULL || p_uv_fs_req_cleanup == NULL)
    return 1;

  if (lstat(path, &st) != 0) {
    perror("lstat");
    return 1;
  }

  if (st.st_size != 0)
    return fail("expected /proc/self/exe to report st_size == 0");

  n = readlink(path, expected, sizeof(expected) - 1);
  if (n < 0) {
    perror("readlink");
    return 1;
  }
  expected[n] = '\0';

  memset(&req, 0, sizeof(req));
  r = p_uv_fs_readlink(NULL, &req, path, NULL);
  if (r != 0) {
    fprintf(stderr, "uv_fs_readlink failed: %d\n", r);
    return 1;
  }

  if (req.ptr == NULL)
    return fail("uv_fs_readlink returned a null result buffer");

  if (strcmp((const char*) req.ptr, expected) != 0) {
    fprintf(stderr,
            "uv_fs_readlink mismatch\nexpected: %s\nactual:   %s\n",
            expected,
            (const char*) req.ptr);
    p_uv_fs_req_cleanup(&req);
    return 1;
  }

  p_uv_fs_req_cleanup(&req);
  return 0;
}
