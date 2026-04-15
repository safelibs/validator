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

#if defined(_WIN32) && !defined(USING_UV_SHARED)

#include "uv.h"
#include "task.h"
#include <string.h>

static uv_file fs_open_file(const char* path, int flags) {
  uv_fs_t req;
  uv_file fd;

  fd = uv_fs_open(NULL, &req, path, flags, S_IWUSR | S_IRUSR, NULL);
  ASSERT_GE(fd, 0);
  ASSERT_EQ(fd, req.result);
  uv_fs_req_cleanup(&req);

  return fd;
}

static void fs_close_file(uv_file fd) {
  uv_fs_t req;

  ASSERT_OK(uv_fs_close(NULL, &req, fd, NULL));
  ASSERT_OK(req.result);
  uv_fs_req_cleanup(&req);
}

static void fs_write_file(uv_file fd, const char* data, size_t len, int64_t offset) {
  uv_fs_t req;
  uv_buf_t buf;

  buf = uv_buf_init((char*) data, len);
  ASSERT_EQ((int) len, uv_fs_write(NULL, &req, fd, &buf, 1, offset, NULL));
  ASSERT_EQ((int) len, req.result);
  uv_fs_req_cleanup(&req);
}

static void fs_read_file(uv_file fd, char* data, size_t len, int64_t offset) {
  uv_fs_t req;
  uv_buf_t buf;

  buf = uv_buf_init(data, len);
  ASSERT_EQ((int) len, uv_fs_read(NULL, &req, fd, &buf, 1, offset, NULL));
  ASSERT_EQ((int) len, req.result);
  uv_fs_req_cleanup(&req);
}

TEST_IMPL(fs_fd_hash) {
  uv_fs_t req;
  uv_file fd1;
  uv_file fd2;
  uv_file fd3;
  const char path[] = "fs_fd_hash_test_file";
  char byte[1];
  char contents[5];

  ASSERT(uv_fs_unlink(NULL, &req, path, NULL) == 0 || req.result == UV_ENOENT);
  uv_fs_req_cleanup(&req);

  fd1 = fs_open_file(path, UV_FS_O_TRUNC | UV_FS_O_CREAT | UV_FS_O_RDWR);
  fs_write_file(fd1, "abcd", 4, 0);
  fs_close_file(fd1);

  fd1 = fs_open_file(path, UV_FS_O_FILEMAP | UV_FS_O_RDWR);
  fd2 = fs_open_file(path, UV_FS_O_FILEMAP | UV_FS_O_RDWR);

  fs_read_file(fd1, byte, 1, -1);
  ASSERT_EQ('a', byte[0]);

  fs_write_file(fd2, "X", 1, -1);
  fs_write_file(fd1, "Y", 1, -1);

  fs_read_file(fd1, byte, 1, -1);
  ASSERT_EQ('c', byte[0]);

  fs_read_file(fd2, byte, 1, -1);
  ASSERT_EQ('Y', byte[0]);

  fs_close_file(fd1);
  fs_close_file(fd2);

  fd3 = fs_open_file(path, UV_FS_O_FILEMAP | UV_FS_O_RDONLY);
  fs_read_file(fd3, contents, 4, 0);
  contents[4] = '\0';
  ASSERT_STR_EQ("XYcd", contents);
  fs_close_file(fd3);

  ASSERT_OK(uv_fs_unlink(NULL, &req, path, NULL));
  ASSERT_OK(req.result);
  uv_fs_req_cleanup(&req);

  return 0;
}

#else

typedef int file_has_no_tests;  /* ISO C forbids an empty translation unit. */

#endif  /* ifndef _WIN32 */
