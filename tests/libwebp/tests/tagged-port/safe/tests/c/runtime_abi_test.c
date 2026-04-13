#include <stdint.h>
#include <string.h>

#include "webp/types.h"

typedef enum {
  kSSE2 = 0,
  kSSE3,
  kSlowSSSE3,
  kSSE4_1,
  kAVX,
  kAVX2,
  kNEON,
  kMIPS32,
  kMIPSdspR2,
  kMSA
} CPUFeature;

typedef int (*VP8CPUInfo)(CPUFeature feature);
extern VP8CPUInfo VP8GetCPUInfo;

typedef enum {
  NOT_OK = 0,
  OK = 1,
  WORK = 2
} WebPWorkerStatus;

typedef int (*WebPWorkerHook)(void*, void*);

typedef struct {
  void* impl_;
  WebPWorkerStatus status_;
  WebPWorkerHook hook;
  void* data1;
  void* data2;
  int had_error;
} WebPWorker;

typedef struct {
  void (*Init)(WebPWorker* const worker);
  int (*Reset)(WebPWorker* const worker);
  int (*Sync)(WebPWorker* const worker);
  void (*Launch)(WebPWorker* const worker);
  void (*Execute)(WebPWorker* const worker);
  void (*End)(WebPWorker* const worker);
} WebPWorkerInterface;

extern int WebPSetWorkerInterface(const WebPWorkerInterface* const winterface);
extern const WebPWorkerInterface* WebPGetWorkerInterface(void);

static int g_hook_calls = 0;
static int g_last_feature = -1;

static int TestHook(void* data1, void* data2) {
  int* const left = (int*)data1;
  int* const right = (int*)data2;
  ++g_hook_calls;
  *left += 7;
  *right += 11;
  return 1;
}

static int FakeCPUInfo(CPUFeature feature) {
  g_last_feature = (int)feature;
  return 1;
}

static void CustomInit(WebPWorker* const worker) {
  memset(worker, 0, sizeof(*worker));
  worker->status_ = NOT_OK;
}

static int CustomReset(WebPWorker* const worker) {
  worker->had_error = 0;
  worker->status_ = OK;
  return 1;
}

static int CustomSync(WebPWorker* const worker) {
  return worker->had_error == 0;
}

static void CustomExecute(WebPWorker* const worker) {
  if (worker->hook != NULL) {
    worker->had_error |= !worker->hook(worker->data1, worker->data2);
  }
}

static void CustomLaunch(WebPWorker* const worker) {
  worker->status_ = WORK;
  CustomExecute(worker);
  worker->status_ = OK;
}

static void CustomEnd(WebPWorker* const worker) {
  worker->status_ = NOT_OK;
  worker->impl_ = NULL;
}

int main(void) {
  const WebPWorkerInterface* const current = WebPGetWorkerInterface();
  WebPWorkerInterface saved;
  WebPWorkerInterface invalid;
  WebPWorkerInterface custom;
  const WebPWorkerInterface* installed;
  VP8CPUInfo original_cpu;
  WebPWorker worker;
  int left = 1;
  int right = 2;

  if (current == NULL || current->Init == NULL || current->Reset == NULL ||
      current->Sync == NULL || current->Launch == NULL ||
      current->Execute == NULL || current->End == NULL) {
    return 1;
  }
  saved = *current;

  if (WebPSetWorkerInterface(NULL) != 0) return 2;
  invalid = saved;
  invalid.Execute = NULL;
  if (WebPSetWorkerInterface(&invalid) != 0) return 3;

  original_cpu = VP8GetCPUInfo;
  if (original_cpu == NULL) return 4;
  VP8GetCPUInfo = FakeCPUInfo;
  if (VP8GetCPUInfo == NULL || !VP8GetCPUInfo(kSSE2) || g_last_feature != kSSE2) {
    return 5;
  }
  VP8GetCPUInfo = original_cpu;

  custom.Init = CustomInit;
  custom.Reset = CustomReset;
  custom.Sync = CustomSync;
  custom.Launch = CustomLaunch;
  custom.Execute = CustomExecute;
  custom.End = CustomEnd;
  if (!WebPSetWorkerInterface(&custom)) return 6;

  custom.Execute = NULL;
  installed = WebPGetWorkerInterface();
  if (installed == NULL || installed->Execute != CustomExecute ||
      installed->Launch != CustomLaunch) {
    return 7;
  }

  memset(&worker, 0, sizeof(worker));
  installed->Init(&worker);
  worker.hook = TestHook;
  worker.data1 = &left;
  worker.data2 = &right;
  if (!installed->Reset(&worker)) return 8;
  installed->Launch(&worker);
  if (g_hook_calls != 1 || left != 8 || right != 13) return 9;
  if (!installed->Sync(&worker)) return 10;
  installed->End(&worker);
  if (worker.status_ != NOT_OK) return 11;

  if (!WebPSetWorkerInterface(&saved)) return 12;
  installed = WebPGetWorkerInterface();
  if (installed == NULL || installed->Init != saved.Init ||
      installed->Execute != saved.Execute || installed->End != saved.End) {
    return 13;
  }

  return 0;
}
