/* Copyright The libuv project and contributors. All rights reserved.
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
#ifndef _WIN32
# include <dlfcn.h>
# include <unistd.h>
#endif
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int getaddrinfo_sync(uv_loop_t* loop,
                            const char* node,
                            struct addrinfo** res) {
  uv_getaddrinfo_t req;
  int r;

  memset(&req, 0, sizeof(req));
  r = uv_getaddrinfo(loop, &req, NULL, node, NULL, NULL);
  if (res != NULL)
    *res = req.addrinfo;
  else
    uv_freeaddrinfo(req.addrinfo);

  return r;
}

#ifndef _WIN32

enum idna_resolver_mode {
  IDNA_RESOLVER_PASSTHROUGH = 0,
  IDNA_RESOLVER_EXPECT_ASCII,
  IDNA_RESOLVER_FORBID
};

typedef int (*idna_getaddrinfo_fn)(const char* node,
                                   const char* service,
                                   const struct addrinfo* hints,
                                   struct addrinfo** res);
typedef void (*idna_freeaddrinfo_fn)(struct addrinfo* ai);

struct fake_addrinfo {
  struct fake_addrinfo* next;
  struct addrinfo ai;
  struct sockaddr_in addr;
  char canonname[256];
};

#if defined(__GNUC__) || defined(__clang__)
# define IDNA_INTERCEPT_EXPORT __attribute__((visibility("default")))
#else
# define IDNA_INTERCEPT_EXPORT
#endif

static enum idna_resolver_mode idna_resolver_mode;
static const char* idna_expected_node;
static int idna_resolver_call_count;
static struct fake_addrinfo* idna_fake_results;
static idna_getaddrinfo_fn real_getaddrinfo_fn;
static idna_freeaddrinfo_fn real_freeaddrinfo_fn;

static void idna_load_real_resolver(void) {
  if (real_getaddrinfo_fn != NULL && real_freeaddrinfo_fn != NULL)
    return;

  real_getaddrinfo_fn = (idna_getaddrinfo_fn) dlsym(RTLD_NEXT, "getaddrinfo");
  real_freeaddrinfo_fn = (idna_freeaddrinfo_fn) dlsym(RTLD_NEXT, "freeaddrinfo");

  ASSERT_NOT_NULL(real_getaddrinfo_fn);
  ASSERT_NOT_NULL(real_freeaddrinfo_fn);
}

static void idna_expect_ascii_query(const char* node) {
  idna_resolver_mode = IDNA_RESOLVER_EXPECT_ASCII;
  idna_expected_node = node;
  idna_resolver_call_count = 0;
}

static void idna_expect_no_resolver_call(void) {
  idna_resolver_mode = IDNA_RESOLVER_FORBID;
  idna_expected_node = NULL;
  idna_resolver_call_count = 0;
}

static void idna_reset_resolver(void) {
  ASSERT_NULL(idna_fake_results);
  idna_resolver_mode = IDNA_RESOLVER_PASSTHROUGH;
  idna_expected_node = NULL;
  idna_resolver_call_count = 0;
}

static void idna_assert_resolver_call_count(int expected) {
  ASSERT_EQ(expected, idna_resolver_call_count);
  idna_reset_resolver();
}

IDNA_INTERCEPT_EXPORT
int getaddrinfo(const char* node,
                const char* service,
                const struct addrinfo* hints,
                struct addrinfo** res) {
  struct fake_addrinfo* fake;

  if (idna_resolver_mode == IDNA_RESOLVER_PASSTHROUGH) {
    idna_load_real_resolver();
    return real_getaddrinfo_fn(node, service, hints, res);
  }

  idna_resolver_call_count++;

  if (idna_resolver_mode == IDNA_RESOLVER_FORBID)
    return EAI_FAIL;

  ASSERT_NOT_NULL(node);
  ASSERT_NOT_NULL(res);
  ASSERT_NULL(service);
  ASSERT_STR_EQ(idna_expected_node, node);

  fake = calloc(1, sizeof(*fake));
  ASSERT_NOT_NULL(fake);

  fake->ai.ai_family = AF_INET;
  fake->ai.ai_addr = (struct sockaddr*) &fake->addr;
  fake->ai.ai_addrlen = sizeof(fake->addr);
  if (hints != NULL) {
    fake->ai.ai_socktype = hints->ai_socktype;
    fake->ai.ai_protocol = hints->ai_protocol;
  }

  fake->addr.sin_family = AF_INET;
  fake->addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);

  if (hints != NULL && (hints->ai_flags & AI_CANONNAME) != 0) {
    snprintf(fake->canonname, sizeof(fake->canonname), "%s", node);
    fake->ai.ai_canonname = fake->canonname;
  }

  fake->next = idna_fake_results;
  idna_fake_results = fake;
  *res = &fake->ai;
  return 0;
}

IDNA_INTERCEPT_EXPORT
void freeaddrinfo(struct addrinfo* ai) {
  struct fake_addrinfo** p;

  if (ai == NULL)
    return;

  for (p = &idna_fake_results; *p != NULL; p = &(*p)->next) {
    if (&(*p)->ai == ai) {
      struct fake_addrinfo* fake = *p;
      *p = fake->next;
      free(fake);
      return;
    }
  }

  idna_load_real_resolver();
  real_freeaddrinfo_fn(ai);
}

#undef IDNA_INTERCEPT_EXPORT

#endif  /* !_WIN32 */

static void assert_getaddrinfo_invalid(const char* node) {
  uv_loop_t loop;

#ifndef _WIN32
  idna_expect_no_resolver_call();
#endif
  ASSERT_OK(uv_loop_init(&loop));
  ASSERT_EQ(UV_EINVAL, getaddrinfo_sync(&loop, node, NULL));
  MAKE_VALGRIND_HAPPY(&loop);
#ifndef _WIN32
  idna_assert_resolver_call_count(0);
#endif
}

static void resolve_ipv4_with_canonname(uv_loop_t* loop,
                                        const char* node,
                                        char ip[sizeof("255.255.255.255")],
                                        char* canonname,
                                        size_t canonname_len) {
  uv_getaddrinfo_t req;
  struct addrinfo hints;
  struct addrinfo* res;

  memset(&req, 0, sizeof(req));
  memset(&hints, 0, sizeof(hints));
  hints.ai_family = AF_INET;
  if (canonname != NULL)
    hints.ai_flags = AI_CANONNAME;

  ASSERT_OK(uv_getaddrinfo(loop, &req, NULL, node, NULL, &hints));
  res = req.addrinfo;
  ASSERT_NOT_NULL(res);
  ASSERT_EQ(AF_INET, res->ai_family);
  ASSERT_OK(uv_ip4_name((const struct sockaddr_in*) res->ai_addr,
                        ip,
                        sizeof("255.255.255.255")));
  if (canonname != NULL) {
    ASSERT_NOT_NULL(res->ai_canonname);
    snprintf(canonname, canonname_len, "%s", res->ai_canonname);
  }
  uv_freeaddrinfo(res);
}

#ifndef _WIN32
static void assert_idna_toascii(const char* input, const char* expected) {
  uv_loop_t loop;
  char ip[sizeof("255.255.255.255")];
  char canonname[256];

  ASSERT_OK(uv_loop_init(&loop));
  idna_expect_ascii_query(expected);
  resolve_ipv4_with_canonname(&loop, input, ip, canonname, sizeof(canonname));
  ASSERT_STR_EQ("127.0.0.1", ip);
  ASSERT_STR_EQ(expected, canonname);
  idna_assert_resolver_call_count(1);

  idna_expect_ascii_query(expected);
  resolve_ipv4_with_canonname(&loop, expected, ip, canonname, sizeof(canonname));
  ASSERT_STR_EQ("127.0.0.1", ip);
  ASSERT_STR_EQ(expected, canonname);
  idna_assert_resolver_call_count(1);

  MAKE_VALGRIND_HAPPY(&loop);
}
#endif  /* !_WIN32 */

#ifdef _WIN32
static int can_resolve_localhost_alias(const char* node) {
  uv_loop_t loop;
  uv_getaddrinfo_t req;
  struct addrinfo hints;
  int r;

  ASSERT_OK(uv_loop_init(&loop));
  memset(&req, 0, sizeof(req));
  memset(&hints, 0, sizeof(hints));
  hints.ai_family = AF_INET;
  hints.ai_flags = AI_CANONNAME;

  r = uv_getaddrinfo(&loop, &req, NULL, node, NULL, &hints);
  if (r == 0)
    uv_freeaddrinfo(req.addrinfo);

  MAKE_VALGRIND_HAPPY(&loop);
  return r == 0;
}

static void assert_windows_idna_resolves(const char* unicode,
                                         const char* ascii) {
  uv_loop_t loop;
  char unicode_ip[sizeof("255.255.255.255")];
  char ascii_ip[sizeof("255.255.255.255")];
  char unicode_canon[256];
  char ascii_canon[256];

  ASSERT_OK(uv_loop_init(&loop));
  resolve_ipv4_with_canonname(&loop,
                              unicode,
                              unicode_ip,
                              unicode_canon,
                              sizeof(unicode_canon));
  resolve_ipv4_with_canonname(&loop,
                              ascii,
                              ascii_ip,
                              ascii_canon,
                              sizeof(ascii_canon));
  ASSERT_STR_EQ("127.0.0.1", unicode_ip);
  ASSERT_STR_EQ(unicode_ip, ascii_ip);
  ASSERT_STR_EQ(ascii, unicode_canon);
  ASSERT_STR_EQ(ascii, ascii_canon);
  MAKE_VALGRIND_HAPPY(&loop);
}
#endif  /* _WIN32 */

TEST_IMPL(utf8_decode1) {
  assert_getaddrinfo_invalid("\xC0\x80\xC1\x80.invalid.");
  assert_getaddrinfo_invalid("\xED\xA0\x80\xED\xA3\xBF.invalid.");
  assert_getaddrinfo_invalid("\xF4\x90\xC0\xC0.invalid.");
  return 0;
}

TEST_IMPL(utf8_decode1_overrun) {
  char truncated_2[] = { (char) 0xC2, '\0' };
  char truncated_3[] = { (char) 0xE0, (char) 0xA0, '\0' };
  char empty[] = "";

  assert_getaddrinfo_invalid(truncated_2);
  assert_getaddrinfo_invalid(truncated_3);
  assert_getaddrinfo_invalid(empty);
  return 0;
}

/* Doesn't work on z/OS because that platform uses EBCDIC, not ASCII. */
#ifndef __MVS__

#ifndef _WIN32
#define F(input) assert_getaddrinfo_invalid("" input "")
#define T(input, expected) assert_idna_toascii("" input "", expected)
#endif

TEST_IMPL(idna_toascii) {
#ifdef _WIN32
  if (!can_resolve_localhost_alias("xn--maana-pta.localhost"))
    RETURN_SKIP("System resolver does not resolve *.localhost names.");

  assert_windows_idna_resolves("mañana.localhost",
                               "xn--maana-pta.localhost");
  assert_windows_idna_resolves("mañana。localhost",
                               "xn--maana-pta.localhost");
  assert_windows_idna_resolves("bücher.localhost",
                               "xn--bcher-kva.localhost");
  assert_windows_idna_resolves("☃-⌘.localhost",
                               "xn----dqo34k.localhost");
#else
  F("\xC0\x80\xC1\x80");
  F("\xC0\x80\xC1\x80.com");
  F("");
  T(".", ".");
  T(".com", ".com");
  T("example", "example");
  T("example-", "example-");
  T("straße.de", "xn--strae-oqa.de");
  T("foo.bar", "foo.bar");
  T("mañana.com", "xn--maana-pta.com");
  T("example.com.", "example.com.");
  T("bücher.com", "xn--bcher-kva.com");
  T("café.com", "xn--caf-dma.com");
  T("café.café.com", "xn--caf-dma.xn--caf-dma.com");
  T("☃-⌘.com", "xn----dqo34k.com");
  T("퐀☃-⌘.com", "xn----dqo34kn65z.com");
  T("💩.la", "xn--ls8h.la");
  T("mañana。com", "xn--maana-pta.com");
  T("mañana．com", "xn--maana-pta.com");
  T("mañana｡com", "xn--maana-pta.com");
  T("ü", "xn--tda");
  T(".ü", ".xn--tda");
  T("ü.ü", "xn--tda.xn--tda");
  T("ü.ü.", "xn--tda.xn--tda.");
  T("üëäö♥", "xn--4can8av2009b");
  T("Willst du die Blüthe des frühen, die Früchte des späteren Jahres",
    "xn--Willst du die Blthe des frhen, "
    "die Frchte des spteren Jahres-x9e96lkal");
  T("ليهمابتكلموشعربي؟", "xn--egbpdaj6bu4bxfgehfvwxn");
  T("他们为什么不说中文", "xn--ihqwcrb4cv8a8dqg056pqjye");
  T("他們爲什麽不說中文", "xn--ihqwctvzc91f659drss3x8bo0yb");
  T("Pročprostěnemluvíčesky", "xn--Proprostnemluvesky-uyb24dma41a");
  T("למההםפשוטלאמדבריםעברית", "xn--4dbcagdahymbxekheh6e0a7fei0b");
  T("यहलोगहिन्दीक्योंनहींबोलसकतेहैं",
    "xn--i1baa7eci9glrd9b2ae1bj0hfcgg6iyaf8o0a1dig0cd");
  T("なぜみんな日本語を話してくれないのか",
    "xn--n8jok5ay5dzabd5bym9f0cm5685rrjetr6pdxa");
  T("세계의모든사람들이한국어를이해한다면얼마나좋을까",
    "xn--989aomsvi5e83db1d2a355cv1e0vak1d"
    "wrv93d5xbh15a0dt30a5jpsd879ccm6fea98c");
  T("почемужеонинеговорятпорусски", "xn--b1abfaaepdrnnbgefbadotcwatmq2g4l");
  T("PorquénopuedensimplementehablarenEspañol",
    "xn--PorqunopuedensimplementehablarenEspaol-fmd56a");
  T("TạisaohọkhôngthểchỉnóitiếngViệt",
    "xn--TisaohkhngthchnitingVit-kjcr8268qyxafd2f1b9g");
  T("3年B組金八先生", "xn--3B-ww4c5e180e575a65lsy2b");
  T("安室奈美恵-with-SUPER-MONKEYS",
    "xn---with-SUPER-MONKEYS-pc58ag80a8qai00g7n9n");
  T("Hello-Another-Way-それぞれの場所",
    "xn--Hello-Another-Way--fc4qua05auwb3674vfr0b");
  T("ひとつ屋根の下2", "xn--2-u9tlzr9756bt3uc0v");
  T("MajiでKoiする5秒前", "xn--MajiKoi5-783gue6qz075azm5e");
  T("パフィーdeルンバ", "xn--de-jg4avhby1noc0d");
  T("そのスピードで", "xn--d9juau41awczczp");
  T("-> $1.00 <-", "-> $1.00 <-");
  T("faß.de", "xn--fa-hia.de");
  T("βόλος.com", "xn--nxasmm1c.com");
  T("ශ්‍රී.com", "xn--10cl1a0b660p.com");
  T("نامه‌ای.com", "xn--mgba3gch31f060k.com");
#endif
  return 0;
}

#ifndef _WIN32
#undef T
#undef F
#endif

#endif  /* __MVS__ */
