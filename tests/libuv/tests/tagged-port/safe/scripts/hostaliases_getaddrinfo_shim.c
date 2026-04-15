#define _GNU_SOURCE

#include <arpa/inet.h>
#include <dlfcn.h>
#include <netdb.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef int (*real_getaddrinfo_fn)(const char*, const char*, const struct addrinfo*, struct addrinfo**);
typedef void (*real_freeaddrinfo_fn)(struct addrinfo*);

static real_getaddrinfo_fn real_getaddrinfo_ptr;
static real_freeaddrinfo_fn real_freeaddrinfo_ptr;

static void load_real_symbols(void) {
  if (real_getaddrinfo_ptr != NULL && real_freeaddrinfo_ptr != NULL)
    return;

  real_getaddrinfo_ptr = (real_getaddrinfo_fn) dlsym(RTLD_NEXT, "getaddrinfo");
  real_freeaddrinfo_ptr = (real_freeaddrinfo_fn) dlsym(RTLD_NEXT, "freeaddrinfo");
}

static int lookup_hostalias(const char* node, char* target, size_t target_len) {
  const char* path;
  FILE* file;
  char line[512];

  if (node == NULL || target == NULL || target_len == 0)
    return 0;

  path = getenv("HOSTALIASES");
  if (path == NULL || path[0] == '\0')
    return 0;

  file = fopen(path, "r");
  if (file == NULL)
    return 0;

  while (fgets(line, sizeof(line), file) != NULL) {
    char alias[256];
    char canonical[256];

    if (sscanf(line, " %255s %255s", alias, canonical) != 2)
      continue;

    if (strcmp(alias, node) != 0)
      continue;

    snprintf(target, target_len, "%s", canonical);
    fclose(file);
    return 1;
  }

  fclose(file);
  return 0;
}

int getaddrinfo(const char* node,
                const char* service,
                const struct addrinfo* hints,
                struct addrinfo** res) {
  char mapped[256];

  load_real_symbols();

  if (real_getaddrinfo_ptr == NULL)
    return EAI_FAIL;

  if (service == NULL && lookup_hostalias(node, mapped, sizeof(mapped)))
    return real_getaddrinfo_ptr(mapped, service, hints, res);

  return real_getaddrinfo_ptr(node, service, hints, res);
}

void freeaddrinfo(struct addrinfo* ai) {
  load_real_symbols();

  if (real_freeaddrinfo_ptr != NULL)
    real_freeaddrinfo_ptr(ai);
}
