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
#include <string.h>
#include <sys/stat.h>

#ifdef _WIN32
# define S_IFDIR _S_IFDIR
#endif

#define UV_TEST_STRINGIFY_HELPER(v) #v
#define UV_TEST_STRINGIFY(v) UV_TEST_STRINGIFY_HELPER(v)
#define UV_TEST_VERSION_STRING_BASE \
  UV_TEST_STRINGIFY(UV_VERSION_MAJOR) "." \
  UV_TEST_STRINGIFY(UV_VERSION_MINOR) "." \
  UV_TEST_STRINGIFY(UV_VERSION_PATCH)

#if UV_VERSION_IS_RELEASE
# define UV_TEST_VERSION_STRING UV_TEST_VERSION_STRING_BASE
#else
# define UV_TEST_VERSION_STRING \
  UV_TEST_VERSION_STRING_BASE "-" UV_VERSION_SUFFIX
#endif

int cookie1;
int cookie2;
int cookie3;

static uv_once_t once_guard = UV_ONCE_INIT;
static uv_barrier_t once_barrier;
static int loop_new_delete_cb_called;
static int once_cb_called;
static int udp_send_queue_send_cb_called;
static int udp_send_queue_recv_cb_called;
static int udp_send_queue_close_cb_called;

static uv_loop_t udp_send_queue_loop;
static uv_udp_t udp_send_queue_server;
static uv_udp_t udp_send_queue_client;


static void loop_new_delete_timer_cb(uv_timer_t* handle) {
  loop_new_delete_cb_called++;
  uv_close((uv_handle_t*) handle, NULL);
}


static void once_cb(void) {
  once_cb_called++;
}


static void once_thread_cb(void* arg) {
  uv_barrier_wait((uv_barrier_t*) arg);
  uv_once(&once_guard, once_cb);
}


static void print_handles_to_buffer(uv_loop_t* loop,
                                    int only_active,
                                    char* buffer,
                                    size_t size) {
  FILE* stream;
  size_t bytes_read;

  stream = tmpfile();
  ASSERT_NOT_NULL(stream);

  if (only_active)
    uv_print_active_handles(loop, stream);
  else
    uv_print_all_handles(loop, stream);

  ASSERT_OK(fflush(stream));
  ASSERT_OK(fseek(stream, 0, SEEK_SET));

  bytes_read = fread(buffer, 1, size - 1, stream);
  ASSERT_OK(ferror(stream));
  buffer[bytes_read] = '\0';

  ASSERT_OK(fclose(stream));
}


static void udp_send_queue_alloc_cb(uv_handle_t* handle,
                                    size_t suggested_size,
                                    uv_buf_t* buf) {
  static char slab[65536];

  ASSERT_NOT_NULL(handle);
  ASSERT_LE(suggested_size, sizeof(slab));
  buf->base = slab;
  buf->len = sizeof(slab);
}


static void udp_send_queue_close_cb(uv_handle_t* handle) {
  ASSERT_NOT_NULL(handle);
  udp_send_queue_close_cb_called++;
}


static void udp_send_queue_send_cb(uv_udp_send_t* req, int status) {
  ASSERT_NOT_NULL(req);
  ASSERT_OK(status);
  ASSERT_PTR_EQ(req->handle, &udp_send_queue_client);
  udp_send_queue_send_cb_called++;
}


static void udp_send_queue_recv_cb(uv_udp_t* handle,
                                   ssize_t nread,
                                   const uv_buf_t* buf,
                                   const struct sockaddr* addr,
                                   unsigned flags) {
  ASSERT_PTR_EQ(handle, &udp_send_queue_server);

  if (nread == 0) {
    ASSERT_NULL(addr);
    return;
  }

  ASSERT_EQ(4, nread);
  ASSERT_NOT_NULL(addr);
  ASSERT_OK(flags);
  ASSERT_MEM_EQ("PING", buf->base, 4);

  udp_send_queue_recv_cb_called++;

  uv_close((uv_handle_t*) &udp_send_queue_server, udp_send_queue_close_cb);
  uv_close((uv_handle_t*) &udp_send_queue_client, udp_send_queue_close_cb);
}


TEST_IMPL(version) {
  ASSERT_EQ(UV_VERSION_HEX, uv_version());
  ASSERT_STR_EQ(UV_TEST_VERSION_STRING, uv_version_string());
  return 0;
}


TEST_IMPL(loop_new_delete) {
  uv_loop_t* loop;
  uv_timer_t timer;

  loop_new_delete_cb_called = 0;

  loop = uv_loop_new();
  ASSERT_NOT_NULL(loop);

  ASSERT_EQ(sizeof(*loop), uv_loop_size());
  ASSERT_OK(uv_loop_alive(loop));

  ASSERT_OK(uv_timer_init(loop, &timer));
  ASSERT_OK(uv_timer_start(&timer, loop_new_delete_timer_cb, 0, 0));

  ASSERT_EQ(1, uv_loop_alive(loop));
  ASSERT_OK(uv_run(loop, UV_RUN_DEFAULT));
  ASSERT_EQ(1, loop_new_delete_cb_called);
  ASSERT_OK(uv_loop_alive(loop));
  ASSERT_OK(uv_run(loop, UV_RUN_DEFAULT));
  ASSERT_OK(uv_loop_alive(loop));

  uv_loop_delete(loop);
  return 0;
}


TEST_IMPL(print_handles) {
  uv_loop_t loop;
  uv_timer_t timer;
  char all_output[1024];
  char active_output[1024];

  ASSERT_OK(uv_loop_init(&loop));
  ASSERT_OK(uv_timer_init(&loop, &timer));

  print_handles_to_buffer(&loop, 0, all_output, sizeof(all_output));
  ASSERT_NOT_NULL(strstr(all_output, "timer"));

  print_handles_to_buffer(&loop, 1, active_output, sizeof(active_output));
  ASSERT_NULL(strstr(active_output, "timer"));

  ASSERT_OK(uv_timer_start(&timer, loop_new_delete_timer_cb, 1000, 0));
  print_handles_to_buffer(&loop, 1, active_output, sizeof(active_output));
  ASSERT_NOT_NULL(strstr(active_output, "timer"));

  uv_close((uv_handle_t*) &timer, NULL);
  ASSERT_OK(uv_run(&loop, UV_RUN_DEFAULT));
  ASSERT_OK(uv_loop_close(&loop));
  return 0;
}


TEST_IMPL(once) {
  uv_thread_t threads[4];
  unsigned int i;

  once_cb_called = 0;

  ASSERT_OK(uv_barrier_init(&once_barrier, 5));
  for (i = 0; i < 4; i++)
    ASSERT_OK(uv_thread_create(&threads[i], once_thread_cb, &once_barrier));

  uv_barrier_wait(&once_barrier);

  for (i = 0; i < 4; i++)
    ASSERT_OK(uv_thread_join(&threads[i]));

  uv_barrier_destroy(&once_barrier);

  uv_once(&once_guard, once_cb);
  ASSERT_EQ(1, once_cb_called);
  return 0;
}


TEST_IMPL(handle_type_name) {
  ASSERT_OK(strcmp(uv_handle_type_name(UV_NAMED_PIPE), "pipe"));
  ASSERT_OK(strcmp(uv_handle_type_name(UV_UDP), "udp"));
  ASSERT_OK(strcmp(uv_handle_type_name(UV_FILE), "file"));
  ASSERT_NULL(uv_handle_type_name(UV_HANDLE_TYPE_MAX));
  ASSERT_NULL(uv_handle_type_name(UV_HANDLE_TYPE_MAX + 1));
  ASSERT_NULL(uv_handle_type_name(UV_UNKNOWN_HANDLE));
  return 0;
}


TEST_IMPL(req_type_name) {
  ASSERT_OK(strcmp(uv_req_type_name(UV_REQ), "req"));
  ASSERT_OK(strcmp(uv_req_type_name(UV_UDP_SEND), "udp_send"));
  ASSERT_OK(strcmp(uv_req_type_name(UV_WORK), "work"));
  ASSERT_NULL(uv_req_type_name(UV_REQ_TYPE_MAX));
  ASSERT_NULL(uv_req_type_name(UV_REQ_TYPE_MAX + 1));
  ASSERT_NULL(uv_req_type_name(UV_UNKNOWN_REQ));
  return 0;
}


TEST_IMPL(getters_setters) {
  uv_loop_t* loop;
  uv_pipe_t* pipe;
  uv_fs_t* fs;
  int r;

  loop = malloc(uv_loop_size());
  ASSERT_NOT_NULL(loop);
  r = uv_loop_init(loop);
  ASSERT_OK(r);

  uv_loop_set_data(loop, &cookie1);
  ASSERT_PTR_EQ(loop->data, &cookie1);
  ASSERT_PTR_EQ(uv_loop_get_data(loop), &cookie1);

  pipe = malloc(uv_handle_size(UV_NAMED_PIPE));
  r = uv_pipe_init(loop, pipe, 0);
  ASSERT_OK(r);
  ASSERT_EQ(uv_handle_get_type((uv_handle_t*)pipe), UV_NAMED_PIPE);

  ASSERT_PTR_EQ(uv_handle_get_loop((uv_handle_t*)pipe), loop);
  pipe->data = &cookie2;
  ASSERT_PTR_EQ(uv_handle_get_data((uv_handle_t*)pipe), &cookie2);
  uv_handle_set_data((uv_handle_t*)pipe, &cookie1);
  ASSERT_PTR_EQ(uv_handle_get_data((uv_handle_t*)pipe), &cookie1);
  ASSERT_PTR_EQ(pipe->data, &cookie1);

  ASSERT_OK(uv_stream_get_write_queue_size((uv_stream_t*)pipe));
  pipe->write_queue_size++;
  ASSERT_EQ(1, uv_stream_get_write_queue_size((uv_stream_t*)pipe));
  pipe->write_queue_size--;
  uv_close((uv_handle_t*)pipe, NULL);

  r = uv_run(loop, UV_RUN_DEFAULT);
  ASSERT_OK(r);

  fs = malloc(uv_req_size(UV_FS));
  uv_fs_stat(loop, fs, ".", NULL);

  r = uv_run(loop, UV_RUN_DEFAULT);
  ASSERT_OK(r);

  uv_req_set_data((uv_req_t*) fs, &cookie3);
  ASSERT_EQ(uv_req_get_type((uv_req_t*) fs), UV_FS);
  ASSERT_PTR_EQ(uv_req_get_data((uv_req_t*) fs), &cookie3);
  ASSERT_EQ(uv_fs_get_type(fs), UV_FS_STAT);
  ASSERT_OK(uv_fs_get_result(fs));
  ASSERT_PTR_EQ(uv_fs_get_ptr(fs), uv_fs_get_statbuf(fs));
  ASSERT(uv_fs_get_statbuf(fs)->st_mode & S_IFDIR);
  ASSERT_OK(strcmp(uv_fs_get_path(fs), "."));
  uv_fs_req_cleanup(fs);

  r = uv_loop_close(loop);
  ASSERT_OK(r);

  free(pipe);
  free(fs);
  free(loop);
  return 0;
}


TEST_IMPL(udp_send_queue_getters) {
  struct sockaddr_in addr;
  uv_udp_send_t req;
  uv_buf_t buf;

  udp_send_queue_send_cb_called = 0;
  udp_send_queue_recv_cb_called = 0;
  udp_send_queue_close_cb_called = 0;

  ASSERT_OK(uv_loop_init(&udp_send_queue_loop));

  ASSERT_OK(uv_ip4_addr("0.0.0.0", TEST_PORT, &addr));
  ASSERT_OK(uv_udp_init(&udp_send_queue_loop, &udp_send_queue_server));
  ASSERT_OK(uv_udp_bind(&udp_send_queue_server,
                        (const struct sockaddr*) &addr,
                        0));
  ASSERT_OK(uv_udp_recv_start(&udp_send_queue_server,
                              udp_send_queue_alloc_cb,
                              udp_send_queue_recv_cb));

  ASSERT_OK(uv_ip4_addr("127.0.0.1", TEST_PORT, &addr));
  ASSERT_OK(uv_udp_init(&udp_send_queue_loop, &udp_send_queue_client));

  buf = uv_buf_init("PING", 4);
  ASSERT_OK(uv_udp_send(&req,
                        &udp_send_queue_client,
                        &buf,
                        1,
                        (const struct sockaddr*) &addr,
                        udp_send_queue_send_cb));

  ASSERT_EQ(1, uv_udp_get_send_queue_count(&udp_send_queue_client));
  ASSERT_EQ(4, uv_udp_get_send_queue_size(&udp_send_queue_client));
  ASSERT_OK(uv_udp_get_send_queue_count(&udp_send_queue_server));
  ASSERT_OK(uv_udp_get_send_queue_size(&udp_send_queue_server));

  ASSERT_OK(uv_run(&udp_send_queue_loop, UV_RUN_DEFAULT));

  ASSERT_EQ(1, udp_send_queue_send_cb_called);
  ASSERT_EQ(1, udp_send_queue_recv_cb_called);
  ASSERT_EQ(2, udp_send_queue_close_cb_called);
  ASSERT_OK(uv_udp_get_send_queue_count(&udp_send_queue_client));
  ASSERT_OK(uv_udp_get_send_queue_size(&udp_send_queue_client));
  ASSERT_OK(uv_loop_close(&udp_send_queue_loop));
  return 0;
}
