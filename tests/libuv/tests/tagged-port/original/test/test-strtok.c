/* Copyright libuv project contributors. All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to
* deal in the Software without restriction, including without limitation the
* rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
* sell copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
* IN THE SOFTWARE.
*/

#include "uv.h"
#include "task.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#if defined(_AIX) || defined(__PASE__) || defined(__MVS__)

#define EXEPATH_MAX 4096

static uv_process_t child_process;
static uv_pipe_t child_stdout;
static int close_cb_called;
static int exit_cb_called;
static int64_t child_exit_status;
static char output[EXEPATH_MAX];
static int output_used;

static void close_cb(uv_handle_t* handle) {
  (void) handle;
  close_cb_called++;
}

static void exit_cb(uv_process_t* process,
                    int64_t exit_status,
                    int term_signal) {
  ASSERT_OK(term_signal);
  child_exit_status = exit_status;
  exit_cb_called++;
  uv_close((uv_handle_t*) process, close_cb);
}

static void on_alloc(uv_handle_t* handle,
                     size_t suggested_size,
                     uv_buf_t* buf) {
  (void) handle;
  (void) suggested_size;
  ASSERT_LT(output_used, (int) sizeof(output));
  buf->base = output + output_used;
  buf->len = sizeof(output) - output_used;
}

static void on_read(uv_stream_t* stream,
                    ssize_t nread,
                    const uv_buf_t* buf) {
  (void) buf;

  if (nread > 0) {
    output_used += nread;
    ASSERT_LT(output_used, (int) sizeof(output));
    output[output_used] = '\0';
    return;
  }

  ASSERT_EQ(UV_EOF, nread);
  uv_close((uv_handle_t*) stream, close_cb);
}

static void split_executable_path(const char* path,
                                  char* dir,
                                  size_t dir_size,
                                  char* base,
                                  size_t base_size) {
  const char* slash;
  size_t dir_len;

  slash = strrchr(path, '/');
  ASSERT_NOT_NULL(slash);
  dir_len = slash - path;
  ASSERT_LT(dir_len, dir_size);

  memcpy(dir, path, dir_len);
  dir[dir_len] = '\0';
  snprintf(base, base_size, "%s", slash + 1);
}

int strtok_helper(void) {
  char path[EXEPATH_MAX];
  size_t path_len;

  path_len = sizeof(path);
  ASSERT_OK(uv_exepath(path, &path_len));
  ASSERT_EQ((int) path_len, (int) strlen(path));
  ASSERT_GT(fprintf(stdout, "%s", path), 0);

  return 0;
}

#endif  /* defined(_AIX) || defined(__PASE__) || defined(__MVS__) */

TEST_IMPL(strtok) {
#if !defined(_AIX) && !defined(__PASE__) && !defined(__MVS__)
  RETURN_SKIP("No public libuv API reaches uv__strtok on this platform.");
#else
  uv_loop_t loop;
  uv_process_options_t options;
  uv_stdio_container_t stdio[3];
  char exepath[EXEPATH_MAX];
  size_t exepath_len;
  char exedir[EXEPATH_MAX];
  char exename[EXEPATH_MAX];
  char* args[3];
  char* path_env;
  char* old_path;
  char* old_path_copy;
  int r;

  exepath_len = sizeof(exepath);
  ASSERT_OK(uv_exepath(exepath, &exepath_len));
  split_executable_path(exepath, exedir, sizeof(exedir), exename, sizeof(exename));

  close_cb_called = 0;
  exit_cb_called = 0;
  child_exit_status = -1;
  output_used = 0;
  output[0] = '\0';

  ASSERT_OK(uv_loop_init(&loop));
  ASSERT_OK(uv_pipe_init(&loop, &child_stdout, 0));

  old_path = getenv("PATH");
  old_path_copy = old_path != NULL ? strdup(old_path) : NULL;
  ASSERT(old_path == NULL || old_path_copy != NULL);

  path_env = malloc(strlen(exedir) + (old_path ? strlen(old_path) : 0) + 32);
  ASSERT_NOT_NULL(path_env);

  if (old_path != NULL)
    snprintf(path_env,
             strlen(exedir) + strlen(old_path) + 32,
             "/definitely-missing::%s:%s",
             exedir,
             old_path);
  else
    snprintf(path_env,
             strlen(exedir) + 32,
             "/definitely-missing::%s",
             exedir);

  ASSERT_OK(setenv("PATH", path_env, 1));

  args[0] = exename;
  args[1] = "strtok_helper";
  args[2] = NULL;

  memset(&options, 0, sizeof(options));
  options.file = exename;
  options.args = args;
  options.exit_cb = exit_cb;
  options.stdio = stdio;
  options.stdio_count = ARRAY_SIZE(stdio);

  stdio[0].flags = UV_IGNORE;
  stdio[1].flags = UV_CREATE_PIPE | UV_WRITABLE_PIPE;
  stdio[1].data.stream = (uv_stream_t*) &child_stdout;
  stdio[2].flags = UV_IGNORE;

  r = uv_spawn(&loop, &child_process, &options);

  if (old_path_copy != NULL) {
    ASSERT_OK(setenv("PATH", old_path_copy, 1));
    free(old_path_copy);
  } else {
    ASSERT_OK(unsetenv("PATH"));
  }

  free(path_env);
  ASSERT_OK(r);

  ASSERT_OK(uv_read_start((uv_stream_t*) &child_stdout, on_alloc, on_read));
  ASSERT_OK(uv_run(&loop, UV_RUN_DEFAULT));

  ASSERT_EQ(1, exit_cb_called);
  ASSERT_EQ(0, child_exit_status);
  ASSERT_EQ(2, close_cb_called);
  ASSERT_STR_EQ(exepath, output);

  MAKE_VALGRIND_HAPPY(&loop);
  return 0;
#endif  /* defined(_AIX) || defined(__PASE__) || defined(__MVS__) */
}
