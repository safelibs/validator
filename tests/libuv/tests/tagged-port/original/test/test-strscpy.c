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
#include <string.h>

TEST_IMPL(strscpy) {
  struct sockaddr_in addr4;
  struct sockaddr_in6 addr6;
  uv_utsname_t uname;
  char err_exact[sizeof("EINVAL")];
  char err_short[4] = { 'x', 'x', 'x', 'x' };
  char ip4_exact[sizeof("255.255.255.255")];
  char ip4_short[sizeof("255.255.255.255") - 1];
  char ip6_exact[sizeof("::1")];
  char ip6_short[sizeof("::1") - 1];

  ASSERT_PTR_EQ(err_exact,
                uv_err_name_r(UV_EINVAL, err_exact, sizeof(err_exact)));
  ASSERT_STR_EQ("EINVAL", err_exact);

  ASSERT_PTR_EQ(err_short,
                uv_err_name_r(UV_EINVAL, err_short, sizeof(err_short)));
  ASSERT_OK(strncmp(err_short, "EIN", sizeof(err_short) - 1));
  ASSERT_EQ('\0', err_short[sizeof(err_short) - 1]);

  ASSERT_OK(uv_ip4_addr("255.255.255.255", TEST_PORT, &addr4));
  ASSERT_OK(uv_ip4_name(&addr4, ip4_exact, sizeof(ip4_exact)));
  ASSERT_STR_EQ("255.255.255.255", ip4_exact);
  ASSERT_EQ(UV_ENOSPC, uv_ip4_name(&addr4, ip4_short, sizeof(ip4_short)));

  ASSERT_OK(uv_ip6_addr("::1", TEST_PORT, &addr6));
  ASSERT_OK(uv_ip6_name(&addr6, ip6_exact, sizeof(ip6_exact)));
  ASSERT_STR_EQ("::1", ip6_exact);
  ASSERT_EQ(UV_ENOSPC, uv_ip6_name(&addr6, ip6_short, sizeof(ip6_short)));

  ASSERT_OK(uv_os_uname(&uname));
  ASSERT_LT(strlen(uname.sysname), sizeof(uname.sysname));
  ASSERT_LT(strlen(uname.release), sizeof(uname.release));
  ASSERT_LT(strlen(uname.version), sizeof(uname.version));
  ASSERT_LT(strlen(uname.machine), sizeof(uname.machine));

  return 0;
}
