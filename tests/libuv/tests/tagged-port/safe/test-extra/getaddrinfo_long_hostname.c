#include <uv.h>

#include <arpa/inet.h>
#include <dlfcn.h>
#include <netdb.h>
#include <netinet/in.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define LABEL_COUNT 20
#define ASCII_LABEL "xn--maana-pta"
#define UNICODE_LABEL "ma\xC3\xB1" "ana"

#if defined(__GNUC__) || defined(__clang__)
#define EXPORT __attribute__((visibility("default")))
#else
#define EXPORT
#endif

struct fake_addrinfo {
  struct fake_addrinfo* next;
  struct addrinfo ai;
  struct sockaddr_in addr;
  char canonname[4096];
};

static const char* expected_node;
static struct fake_addrinfo* fake_results;
static char seen_node[4096];
static int resolver_calls;
static int resolver_mismatch;

typedef int (*uv_loop_init_fn)(uv_loop_t*);
typedef int (*uv_getaddrinfo_fn)(uv_loop_t*,
                                 uv_getaddrinfo_t*,
                                 uv_getaddrinfo_cb,
                                 const char*,
                                 const char*,
                                 const struct addrinfo*);
typedef void (*uv_freeaddrinfo_fn)(struct addrinfo*);
typedef int (*uv_loop_close_fn)(uv_loop_t*);

static uv_loop_init_fn p_uv_loop_init;
static uv_getaddrinfo_fn p_uv_getaddrinfo;
static uv_freeaddrinfo_fn p_uv_freeaddrinfo;
static uv_loop_close_fn p_uv_loop_close;

static int failf(const char* fmt, ...) {
  va_list ap;

  va_start(ap, fmt);
  vfprintf(stderr, fmt, ap);
  va_end(ap);
  fputc('\n', stderr);
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

static int load_uv(void) {
  void* uv_lib;

  uv_lib = dlopen("libuv.so.1", RTLD_NOW | RTLD_GLOBAL);
  if (uv_lib == NULL)
    return failf("%s", dlerror());

  p_uv_loop_init = (uv_loop_init_fn) load_symbol(uv_lib, "uv_loop_init");
  p_uv_getaddrinfo = (uv_getaddrinfo_fn) load_symbol(uv_lib, "uv_getaddrinfo");
  p_uv_freeaddrinfo =
      (uv_freeaddrinfo_fn) load_symbol(uv_lib, "uv_freeaddrinfo");
  p_uv_loop_close = (uv_loop_close_fn) load_symbol(uv_lib, "uv_loop_close");

  if (p_uv_loop_init == NULL || p_uv_getaddrinfo == NULL ||
      p_uv_freeaddrinfo == NULL || p_uv_loop_close == NULL)
    return 1;

  return 0;
}

static int build_hostname(char* out,
                          size_t out_len,
                          const char* label,
                          size_t count) {
  size_t used;
  size_t i;

  if (out_len == 0)
    return -1;

  out[0] = '\0';
  used = 0;

  for (i = 0; i < count; i++) {
    int written;

    written = snprintf(out + used,
                       out_len - used,
                       "%s%s",
                       i == 0 ? "" : ".",
                       label);
    if (written < 0 || (size_t) written >= out_len - used)
      return -1;
    used += (size_t) written;
  }

  return 0;
}

EXPORT
int getaddrinfo(const char* node,
                const char* service,
                const struct addrinfo* hints,
                struct addrinfo** res) {
  struct fake_addrinfo* fake;

  resolver_calls++;

  if (node == NULL || res == NULL || service != NULL)
    return EAI_FAIL;

  snprintf(seen_node, sizeof(seen_node), "%s", node);
  if (strcmp(node, expected_node) != 0) {
    resolver_mismatch = 1;
    return EAI_FAIL;
  }

  fake = calloc(1, sizeof(*fake));
  if (fake == NULL)
    return EAI_MEMORY;

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

  fake->next = fake_results;
  fake_results = fake;
  *res = &fake->ai;
  return 0;
}

EXPORT
void freeaddrinfo(struct addrinfo* ai) {
  struct fake_addrinfo** current;

  if (ai == NULL)
    return;

  for (current = &fake_results; *current != NULL; current = &(*current)->next) {
    if (&(*current)->ai == ai) {
      struct fake_addrinfo* fake = *current;
      *current = fake->next;
      free(fake);
      return;
    }
  }
}

int main(void) {
  char unicode_host[4096];
  char ascii_host[4096];
  uv_loop_t loop;
  uv_getaddrinfo_t req;
  struct addrinfo hints;
  int r;

  if (build_hostname(unicode_host, sizeof(unicode_host), UNICODE_LABEL, LABEL_COUNT) != 0)
    return failf("failed to build unicode hostname");

  if (build_hostname(ascii_host, sizeof(ascii_host), ASCII_LABEL, LABEL_COUNT) != 0)
    return failf("failed to build ASCII hostname");

  if (strlen(ascii_host) <= 255)
    return failf("ASCII hostname did not exceed 255 bytes");

  if (load_uv() != 0)
    return 1;

  expected_node = ascii_host;
  seen_node[0] = '\0';
  resolver_calls = 0;
  resolver_mismatch = 0;

  if (p_uv_loop_init(&loop) != 0)
    return failf("uv_loop_init failed");

  memset(&req, 0, sizeof(req));
  memset(&hints, 0, sizeof(hints));
  hints.ai_family = AF_INET;
  hints.ai_flags = AI_CANONNAME;

  r = p_uv_getaddrinfo(&loop, &req, NULL, unicode_host, NULL, &hints);
  if (r == 0) {
    if (resolver_calls != 1)
      return failf("expected exactly one resolver call on success, got %d", resolver_calls);
    if (resolver_mismatch)
      return failf("resolver saw truncated or altered hostname: %s", seen_node);
    if (strcmp(seen_node, ascii_host) != 0)
      return failf("resolver hostname mismatch");
    if (req.addrinfo == NULL)
      return failf("uv_getaddrinfo succeeded without addrinfo results");
    if (req.addrinfo->ai_canonname == NULL)
      return failf("fake resolver did not propagate canonname");
    if (strcmp(req.addrinfo->ai_canonname, ascii_host) != 0)
      return failf("canonname mismatch");
    p_uv_freeaddrinfo(req.addrinfo);
  } else if (resolver_calls != 0) {
    return failf("uv_getaddrinfo failed after invoking resolver with: %s", seen_node);
  }

  if (fake_results != NULL)
    return failf("fake addrinfo list was not released");

  if (p_uv_loop_close(&loop) != 0)
    return failf("uv_loop_close failed");

  return 0;
}
