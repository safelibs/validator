#define _GNU_SOURCE 1
#include <dlfcn.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "webp/demux.h"

#ifndef TEST_LIBRARY_NAME
#define TEST_LIBRARY_NAME "unknown"
#endif

#ifndef ORACLE_LIBRARY_PATH
#define ORACLE_LIBRARY_PATH ""
#endif

#define CHECK(expr)                                                            \
  do {                                                                         \
    if (!(expr)) {                                                             \
      fprintf(stderr, "[%s] check failed at line %d: %s\n",                    \
              TEST_LIBRARY_NAME, __LINE__, #expr);                             \
      return __LINE__;                                                         \
    }                                                                          \
  } while (0)

static const uint8_t kAnimSample[] = {
    0x52, 0x49, 0x46, 0x46, 0x60, 0x01, 0x00, 0x00, 0x57, 0x45, 0x42, 0x50,
    0x56, 0x50, 0x38, 0x58, 0x0a, 0x00, 0x00, 0x00, 0x3e, 0x00, 0x00, 0x00,
    0x03, 0x00, 0x00, 0x03, 0x00, 0x00, 0x41, 0x42, 0x43, 0x44, 0x03, 0x00,
    0x00, 0x00, 0x6f, 0x6e, 0x65, 0x00, 0x41, 0x42, 0x43, 0x44, 0x04, 0x00,
    0x00, 0x00, 0x74, 0x77, 0x6f, 0x32, 0x49, 0x43, 0x43, 0x50, 0x03, 0x00,
    0x00, 0x00, 0x69, 0x63, 0x63, 0x00, 0x45, 0x58, 0x49, 0x46, 0x04, 0x00,
    0x00, 0x00, 0x65, 0x78, 0x69, 0x66, 0x58, 0x4d, 0x50, 0x20, 0x05, 0x00,
    0x00, 0x00, 0x78, 0x6d, 0x70, 0x21, 0x21, 0x00, 0x41, 0x4e, 0x49, 0x4d,
    0x06, 0x00, 0x00, 0x00, 0xff, 0xff, 0xff, 0xff, 0x00, 0x00, 0x41, 0x4e,
    0x4d, 0x46, 0x48, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x03, 0x00, 0x00, 0x03, 0x00, 0x00, 0x64, 0x00, 0x00, 0x03, 0x56, 0x50,
    0x38, 0x20, 0x30, 0x00, 0x00, 0x00, 0xd0, 0x01, 0x00, 0x9d, 0x01, 0x2a,
    0x04, 0x00, 0x04, 0x00, 0x02, 0x00, 0x34, 0x25, 0xa0, 0x02, 0x74, 0xba,
    0x01, 0xf8, 0x00, 0x03, 0xb0, 0x00, 0xfe, 0xf0, 0xc4, 0x0b, 0xff, 0x20,
    0xb9, 0x61, 0x75, 0xc8, 0xd7, 0xff, 0x20, 0x3f, 0xe4, 0x07, 0xfc, 0x80,
    0xff, 0xf8, 0xf2, 0x00, 0x00, 0x00, 0x41, 0x4e, 0x4d, 0x46, 0x5a, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x02,
    0x00, 0x00, 0x64, 0x00, 0x00, 0x03, 0x41, 0x4c, 0x50, 0x48, 0x0a, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0x80, 0x00, 0x80, 0x80,
    0x56, 0x50, 0x38, 0x20, 0x30, 0x00, 0x00, 0x00, 0x10, 0x02, 0x00, 0x9d,
    0x01, 0x2a, 0x03, 0x00, 0x03, 0x00, 0x02, 0x00, 0x34, 0x25, 0xa0, 0x02,
    0x74, 0xba, 0x01, 0xf8, 0x01, 0xf8, 0x00, 0x03, 0xc8, 0x00, 0xfe, 0xe6,
    0x69, 0xdf, 0xfb, 0x5a, 0x03, 0x83, 0x55, 0xfe, 0x67, 0xff, 0xfb, 0xef,
    0x85, 0x11, 0xdb, 0xaf, 0xf3, 0x14, 0x00, 0x00, 0x41, 0x4e, 0x4d, 0x46,
    0x44, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00,
    0x00, 0x01, 0x00, 0x00, 0xc8, 0x00, 0x00, 0x00, 0x56, 0x50, 0x38, 0x20,
    0x2c, 0x00, 0x00, 0x00, 0x94, 0x01, 0x00, 0x9d, 0x01, 0x2a, 0x02, 0x00,
    0x02, 0x00, 0x00, 0x00, 0x34, 0x25, 0xa0, 0x02, 0x74, 0xba, 0x00, 0x03,
    0x98, 0x00, 0xfe, 0xf9, 0x93, 0x6f, 0xff, 0x76, 0x4f, 0xff, 0xb6, 0x4f,
    0xff, 0xb6, 0x4f, 0xfd, 0xe3, 0x3c, 0x36, 0xaa, 0xc9, 0x68, 0x00, 0x00,
};

static const size_t kFirstRawVp8Offset = 138u;
static const size_t kFirstRawVp8Size = 48u;

typedef struct {
  void* handle;
  WebPDemuxer* (*DemuxInternal)(const WebPData*, int, WebPDemuxState*, int);
  void (*DemuxDelete)(WebPDemuxer*);
  uint32_t (*DemuxGetI)(const WebPDemuxer*, WebPFormatFeature);
  int (*DemuxGetFrame)(const WebPDemuxer*, int, WebPIterator*);
  int (*DemuxNextFrame)(WebPIterator*);
  int (*DemuxPrevFrame)(WebPIterator*);
  void (*DemuxReleaseIterator)(WebPIterator*);
  int (*DemuxGetChunk)(const WebPDemuxer*, const char[4], int, WebPChunkIterator*);
  int (*DemuxNextChunk)(WebPChunkIterator*);
  int (*DemuxPrevChunk)(WebPChunkIterator*);
  void (*DemuxReleaseChunkIterator)(WebPChunkIterator*);
  int (*AnimDecoderOptionsInitInternal)(WebPAnimDecoderOptions*, int);
  WebPAnimDecoder* (*AnimDecoderNewInternal)(const WebPData*,
                                             const WebPAnimDecoderOptions*, int);
  int (*AnimDecoderGetInfo)(const WebPAnimDecoder*, WebPAnimInfo*);
  int (*AnimDecoderGetNext)(WebPAnimDecoder*, uint8_t**, int*);
  int (*AnimDecoderHasMoreFrames)(const WebPAnimDecoder*);
  void (*AnimDecoderReset)(WebPAnimDecoder*);
  const WebPDemuxer* (*AnimDecoderGetDemuxer)(const WebPAnimDecoder*);
  void (*AnimDecoderDelete)(WebPAnimDecoder*);
} OracleApi;

static int CompareBytes(const uint8_t* lhs, const uint8_t* rhs, size_t size) {
  return size == 0 || memcmp(lhs, rhs, size) == 0;
}

static int CompareFrameIterators(const WebPIterator* lhs,
                                 const WebPIterator* rhs) {
  return lhs->frame_num == rhs->frame_num &&
         lhs->num_frames == rhs->num_frames &&
         lhs->x_offset == rhs->x_offset &&
         lhs->y_offset == rhs->y_offset &&
         lhs->width == rhs->width &&
         lhs->height == rhs->height &&
         lhs->duration == rhs->duration &&
         lhs->dispose_method == rhs->dispose_method &&
         lhs->complete == rhs->complete &&
         lhs->fragment.size == rhs->fragment.size &&
         lhs->has_alpha == rhs->has_alpha &&
         lhs->blend_method == rhs->blend_method &&
         CompareBytes(lhs->fragment.bytes, rhs->fragment.bytes, lhs->fragment.size);
}

static int CompareChunkIterators(const WebPChunkIterator* lhs,
                                 const WebPChunkIterator* rhs) {
  return lhs->chunk_num == rhs->chunk_num &&
         lhs->num_chunks == rhs->num_chunks &&
         lhs->chunk.size == rhs->chunk.size &&
         CompareBytes(lhs->chunk.bytes, rhs->chunk.bytes, lhs->chunk.size);
}

static int CompareAnimInfo(const WebPAnimInfo* lhs, const WebPAnimInfo* rhs) {
  return lhs->canvas_width == rhs->canvas_width &&
         lhs->canvas_height == rhs->canvas_height &&
         lhs->loop_count == rhs->loop_count &&
         lhs->bgcolor == rhs->bgcolor &&
         lhs->frame_count == rhs->frame_count;
}

static int LoadOracleApi(OracleApi* api) {
  memset(api, 0, sizeof(*api));
#ifdef LM_ID_NEWLM
  api->handle = dlmopen(LM_ID_NEWLM, ORACLE_LIBRARY_PATH, RTLD_NOW | RTLD_LOCAL);
#else
  api->handle = dlopen(ORACLE_LIBRARY_PATH, RTLD_NOW | RTLD_LOCAL);
#endif
  if (api->handle == NULL) {
    fprintf(stderr, "[%s] failed to load oracle library %s: %s\n",
            TEST_LIBRARY_NAME, ORACLE_LIBRARY_PATH, dlerror());
    return 0;
  }
#define LOAD_ORACLE(symbol, field, type)                                       \
  do {                                                                         \
    api->field = (type)dlsym(api->handle, #symbol);                            \
    if (api->field == NULL) {                                                  \
      fprintf(stderr, "[%s] missing oracle symbol %s: %s\n",                   \
              TEST_LIBRARY_NAME, #symbol, dlerror());                          \
      return 0;                                                                \
    }                                                                          \
  } while (0)
  LOAD_ORACLE(WebPDemuxInternal, DemuxInternal, typeof(api->DemuxInternal));
  LOAD_ORACLE(WebPDemuxDelete, DemuxDelete, typeof(api->DemuxDelete));
  LOAD_ORACLE(WebPDemuxGetI, DemuxGetI, typeof(api->DemuxGetI));
  LOAD_ORACLE(WebPDemuxGetFrame, DemuxGetFrame, typeof(api->DemuxGetFrame));
  LOAD_ORACLE(WebPDemuxNextFrame, DemuxNextFrame, typeof(api->DemuxNextFrame));
  LOAD_ORACLE(WebPDemuxPrevFrame, DemuxPrevFrame, typeof(api->DemuxPrevFrame));
  LOAD_ORACLE(WebPDemuxReleaseIterator, DemuxReleaseIterator,
              typeof(api->DemuxReleaseIterator));
  LOAD_ORACLE(WebPDemuxGetChunk, DemuxGetChunk, typeof(api->DemuxGetChunk));
  LOAD_ORACLE(WebPDemuxNextChunk, DemuxNextChunk, typeof(api->DemuxNextChunk));
  LOAD_ORACLE(WebPDemuxPrevChunk, DemuxPrevChunk, typeof(api->DemuxPrevChunk));
  LOAD_ORACLE(WebPDemuxReleaseChunkIterator, DemuxReleaseChunkIterator,
              typeof(api->DemuxReleaseChunkIterator));
  LOAD_ORACLE(WebPAnimDecoderOptionsInitInternal, AnimDecoderOptionsInitInternal,
              typeof(api->AnimDecoderOptionsInitInternal));
  LOAD_ORACLE(WebPAnimDecoderNewInternal, AnimDecoderNewInternal,
              typeof(api->AnimDecoderNewInternal));
  LOAD_ORACLE(WebPAnimDecoderGetInfo, AnimDecoderGetInfo,
              typeof(api->AnimDecoderGetInfo));
  LOAD_ORACLE(WebPAnimDecoderGetNext, AnimDecoderGetNext,
              typeof(api->AnimDecoderGetNext));
  LOAD_ORACLE(WebPAnimDecoderHasMoreFrames, AnimDecoderHasMoreFrames,
              typeof(api->AnimDecoderHasMoreFrames));
  LOAD_ORACLE(WebPAnimDecoderReset, AnimDecoderReset,
              typeof(api->AnimDecoderReset));
  LOAD_ORACLE(WebPAnimDecoderGetDemuxer, AnimDecoderGetDemuxer,
              typeof(api->AnimDecoderGetDemuxer));
  LOAD_ORACLE(WebPAnimDecoderDelete, AnimDecoderDelete,
              typeof(api->AnimDecoderDelete));
#undef LOAD_ORACLE
  return 1;
}

static void UnloadOracleApi(OracleApi* api) {
  if (api->handle != NULL) {
    dlclose(api->handle);
    api->handle = NULL;
  }
}

static int CompareFeatureSet(const WebPDemuxer* safe_dmux,
                             const WebPDemuxer* oracle_dmux,
                             OracleApi* oracle) {
  int feature;
  for (feature = WEBP_FF_FORMAT_FLAGS; feature <= WEBP_FF_FRAME_COUNT; ++feature) {
    const uint32_t safe_value = WebPDemuxGetI(safe_dmux, (WebPFormatFeature)feature);
    const uint32_t oracle_value =
        oracle->DemuxGetI(oracle_dmux, (WebPFormatFeature)feature);
    if (safe_value != oracle_value) return 0;
  }
  return 1;
}

static int CompareChunkByTag(const WebPDemuxer* safe_dmux,
                             const WebPDemuxer* oracle_dmux,
                             OracleApi* oracle,
                             const char tag[4]) {
  WebPChunkIterator safe_iter;
  WebPChunkIterator oracle_iter;
  const int safe_ok = WebPDemuxGetChunk(safe_dmux, tag, 1, &safe_iter);
  const int oracle_ok = oracle->DemuxGetChunk(oracle_dmux, tag, 1, &oracle_iter);
  if (safe_ok != oracle_ok) return 0;
  if (!safe_ok) return 1;
  if (!CompareChunkIterators(&safe_iter, &oracle_iter)) return 0;
  WebPDemuxReleaseChunkIterator(&safe_iter);
  oracle->DemuxReleaseChunkIterator(&oracle_iter);
  return 1;
}

static int RunDemuxTests(OracleApi* oracle, const WebPData* data) {
  WebPDemuxState safe_state = WEBP_DEMUX_PARSE_ERROR;
  WebPDemuxState oracle_state = WEBP_DEMUX_PARSE_ERROR;
  WebPDemuxer* safe_dmux = NULL;
  WebPDemuxer* oracle_dmux = NULL;
  WebPData partial_data = {kAnimSample, sizeof(kAnimSample) - 17u};
  WebPDemuxer *safe_partial = NULL, *oracle_partial = NULL;
  WebPIterator safe_frame;
  WebPIterator oracle_frame;
  WebPChunkIterator safe_chunk;
  WebPChunkIterator oracle_chunk;

  CHECK(WebPDemuxInternal(NULL, 0, &safe_state, WEBP_DEMUX_ABI_VERSION) == NULL);
  CHECK(oracle->DemuxInternal(NULL, 0, &oracle_state, WEBP_DEMUX_ABI_VERSION) == NULL);
  CHECK(WebPGetDemuxVersion() == 0x010302);

  safe_dmux = WebPDemuxInternal(data, 0, &safe_state, WEBP_DEMUX_ABI_VERSION);
  oracle_dmux = oracle->DemuxInternal(data, 0, &oracle_state, WEBP_DEMUX_ABI_VERSION);
  CHECK(safe_dmux != NULL && oracle_dmux != NULL);
  CHECK(safe_state == oracle_state);
  CHECK(CompareFeatureSet(safe_dmux, oracle_dmux, oracle));
  CHECK(WebPDemuxGetI(safe_dmux, WEBP_FF_FORMAT_FLAGS) == 0x3e);
  CHECK(WebPDemuxGetI(safe_dmux, WEBP_FF_FRAME_COUNT) == 3);

  safe_partial =
      WebPDemuxInternal(&partial_data, 1, &safe_state, WEBP_DEMUX_ABI_VERSION);
  oracle_partial =
      oracle->DemuxInternal(&partial_data, 1, &oracle_state, WEBP_DEMUX_ABI_VERSION);
  CHECK((safe_partial != NULL) == (oracle_partial != NULL));
  CHECK(safe_state == oracle_state);
  if (safe_partial != NULL) {
    CHECK(CompareFeatureSet(safe_partial, oracle_partial, oracle));
    WebPDemuxDelete(safe_partial);
    oracle->DemuxDelete(oracle_partial);
  }

  CHECK(WebPDemuxGetFrame(safe_dmux, 0, &safe_frame) == 1);
  CHECK(oracle->DemuxGetFrame(oracle_dmux, 0, &oracle_frame) == 1);
  CHECK(CompareFrameIterators(&safe_frame, &oracle_frame));
  CHECK(WebPDemuxPrevFrame(&safe_frame) == 1);
  CHECK(oracle->DemuxPrevFrame(&oracle_frame) == 1);
  CHECK(CompareFrameIterators(&safe_frame, &oracle_frame));
  WebPDemuxReleaseIterator(&safe_frame);
  oracle->DemuxReleaseIterator(&oracle_frame);

  CHECK(WebPDemuxGetFrame(safe_dmux, 1, &safe_frame) == 1);
  CHECK(oracle->DemuxGetFrame(oracle_dmux, 1, &oracle_frame) == 1);
  for (;;) {
    int safe_next;
    int oracle_next;
    CHECK(CompareFrameIterators(&safe_frame, &oracle_frame));
    safe_next = WebPDemuxNextFrame(&safe_frame);
    oracle_next = oracle->DemuxNextFrame(&oracle_frame);
    CHECK(safe_next == oracle_next);
    if (!safe_next) break;
  }
  WebPDemuxReleaseIterator(&safe_frame);
  oracle->DemuxReleaseIterator(&oracle_frame);

  CHECK(CompareChunkByTag(safe_dmux, oracle_dmux, oracle, "ICCP"));
  CHECK(CompareChunkByTag(safe_dmux, oracle_dmux, oracle, "EXIF"));
  CHECK(CompareChunkByTag(safe_dmux, oracle_dmux, oracle, "XMP "));

  CHECK(WebPDemuxGetChunk(safe_dmux, "ABCD", 1, &safe_chunk) == 1);
  CHECK(oracle->DemuxGetChunk(oracle_dmux, "ABCD", 1, &oracle_chunk) == 1);
  CHECK(CompareChunkIterators(&safe_chunk, &oracle_chunk));
  CHECK(WebPDemuxNextChunk(&safe_chunk) == 1);
  CHECK(oracle->DemuxNextChunk(&oracle_chunk) == 1);
  CHECK(CompareChunkIterators(&safe_chunk, &oracle_chunk));
  CHECK(WebPDemuxPrevChunk(&safe_chunk) == 1);
  CHECK(oracle->DemuxPrevChunk(&oracle_chunk) == 1);
  CHECK(CompareChunkIterators(&safe_chunk, &oracle_chunk));
  WebPDemuxReleaseChunkIterator(&safe_chunk);
  oracle->DemuxReleaseChunkIterator(&oracle_chunk);

  CHECK(WebPDemuxGetChunk(safe_dmux, "ABCD", 0, &safe_chunk) == 1);
  CHECK(oracle->DemuxGetChunk(oracle_dmux, "ABCD", 0, &oracle_chunk) == 1);
  CHECK(CompareChunkIterators(&safe_chunk, &oracle_chunk));
  WebPDemuxReleaseChunkIterator(&safe_chunk);
  oracle->DemuxReleaseChunkIterator(&oracle_chunk);

  CHECK(WebPDemuxGetChunk(safe_dmux, "MISS", 1, &safe_chunk) == 0);
  CHECK(oracle->DemuxGetChunk(oracle_dmux, "MISS", 1, &oracle_chunk) == 0);

  WebPDemuxDelete(safe_dmux);
  oracle->DemuxDelete(oracle_dmux);
  return 0;
}

static int RunRawDemuxTests(OracleApi* oracle) {
  WebPData raw_data = {kAnimSample + kFirstRawVp8Offset, kFirstRawVp8Size};
  WebPData raw_partial = {kAnimSample + kFirstRawVp8Offset, kFirstRawVp8Size - 1u};
  WebPDemuxState safe_state = WEBP_DEMUX_PARSE_ERROR;
  WebPDemuxState oracle_state = WEBP_DEMUX_PARSE_ERROR;
  WebPDemuxer *safe_dmux = NULL, *oracle_dmux = NULL;
  WebPIterator safe_frame;
  WebPIterator oracle_frame;

  safe_dmux = WebPDemuxInternal(&raw_data, 0, &safe_state, WEBP_DEMUX_ABI_VERSION);
  oracle_dmux = oracle->DemuxInternal(&raw_data, 0, &oracle_state, WEBP_DEMUX_ABI_VERSION);
  CHECK(safe_dmux != NULL && oracle_dmux != NULL);
  CHECK(safe_state == oracle_state);
  CHECK(CompareFeatureSet(safe_dmux, oracle_dmux, oracle));
  CHECK(WebPDemuxGetI(safe_dmux, WEBP_FF_FRAME_COUNT) == 1);
  CHECK(WebPDemuxGetI(safe_dmux, WEBP_FF_FORMAT_FLAGS) == 0);
  CHECK(WebPDemuxGetFrame(safe_dmux, 1, &safe_frame) == 1);
  CHECK(oracle->DemuxGetFrame(oracle_dmux, 1, &oracle_frame) == 1);
  CHECK(CompareFrameIterators(&safe_frame, &oracle_frame));
  WebPDemuxReleaseIterator(&safe_frame);
  oracle->DemuxReleaseIterator(&oracle_frame);
  WebPDemuxDelete(safe_dmux);
  oracle->DemuxDelete(oracle_dmux);

  safe_dmux = WebPDemuxInternal(&raw_partial, 0, &safe_state, WEBP_DEMUX_ABI_VERSION);
  oracle_dmux =
      oracle->DemuxInternal(&raw_partial, 0, &oracle_state, WEBP_DEMUX_ABI_VERSION);
  CHECK((safe_dmux != NULL) == (oracle_dmux != NULL));
  CHECK(safe_state == oracle_state);
  if (safe_dmux != NULL) {
    CHECK(CompareFeatureSet(safe_dmux, oracle_dmux, oracle));
    WebPDemuxDelete(safe_dmux);
    oracle->DemuxDelete(oracle_dmux);
  }

  safe_dmux = WebPDemuxInternal(&raw_partial, 1, &safe_state, WEBP_DEMUX_ABI_VERSION);
  oracle_dmux =
      oracle->DemuxInternal(&raw_partial, 1, &oracle_state, WEBP_DEMUX_ABI_VERSION);
  CHECK((safe_dmux != NULL) == (oracle_dmux != NULL));
  CHECK(safe_state == oracle_state);
  if (safe_dmux != NULL) {
    CHECK(CompareFeatureSet(safe_dmux, oracle_dmux, oracle));
    WebPDemuxDelete(safe_dmux);
    oracle->DemuxDelete(oracle_dmux);
  }
  return 0;
}

static int RunInvalidApiTests(OracleApi* oracle, const WebPData* data) {
  WebPIterator safe_frame;
  WebPIterator oracle_frame;
  WebPChunkIterator safe_chunk;
  WebPChunkIterator oracle_chunk;
  WebPAnimDecoderOptions safe_options;
  WebPAnimDecoderOptions oracle_options;
  WebPAnimDecoder *safe_dec = NULL, *oracle_dec = NULL;
  WebPAnimInfo safe_info;
  WebPAnimInfo oracle_info;
  uint8_t *safe_buf = NULL, *oracle_buf = NULL;
  int safe_ts = 0, oracle_ts = 0;

  CHECK(WebPDemuxGetI(NULL, WEBP_FF_FRAME_COUNT) ==
        oracle->DemuxGetI(NULL, WEBP_FF_FRAME_COUNT));
  CHECK(WebPDemuxGetFrame(NULL, 1, &safe_frame) ==
        oracle->DemuxGetFrame(NULL, 1, &oracle_frame));
  CHECK(WebPDemuxGetFrame(NULL, 1, NULL) ==
        oracle->DemuxGetFrame(NULL, 1, NULL));
  CHECK(WebPDemuxNextFrame(NULL) == oracle->DemuxNextFrame(NULL));
  CHECK(WebPDemuxPrevFrame(NULL) == oracle->DemuxPrevFrame(NULL));
  CHECK(WebPDemuxGetChunk(NULL, "ICCP", 1, &safe_chunk) ==
        oracle->DemuxGetChunk(NULL, "ICCP", 1, &oracle_chunk));
  CHECK(WebPDemuxGetChunk(NULL, "ICCP", 1, NULL) ==
        oracle->DemuxGetChunk(NULL, "ICCP", 1, NULL));
  CHECK(WebPDemuxNextChunk(NULL) == oracle->DemuxNextChunk(NULL));
  CHECK(WebPDemuxPrevChunk(NULL) == oracle->DemuxPrevChunk(NULL));

  CHECK(WebPAnimDecoderOptionsInitInternal(&safe_options,
                                           WEBP_DEMUX_ABI_VERSION - 0x100) ==
        oracle->AnimDecoderOptionsInitInternal(&oracle_options,
                                               WEBP_DEMUX_ABI_VERSION - 0x100));
  CHECK(WebPAnimDecoderGetInfo(NULL, &safe_info) ==
        oracle->AnimDecoderGetInfo(NULL, &oracle_info));
  CHECK(WebPAnimDecoderGetInfo(NULL, NULL) ==
        oracle->AnimDecoderGetInfo(NULL, NULL));
  CHECK(WebPAnimDecoderGetNext(NULL, &safe_buf, &safe_ts) ==
        oracle->AnimDecoderGetNext(NULL, &oracle_buf, &oracle_ts));
  CHECK(WebPAnimDecoderGetNext(NULL, NULL, NULL) ==
        oracle->AnimDecoderGetNext(NULL, NULL, NULL));
  CHECK(WebPAnimDecoderHasMoreFrames(NULL) ==
        oracle->AnimDecoderHasMoreFrames(NULL));
  CHECK((WebPAnimDecoderGetDemuxer(NULL) != NULL) ==
        (oracle->AnimDecoderGetDemuxer(NULL) != NULL));
  WebPAnimDecoderReset(NULL);
  oracle->AnimDecoderReset(NULL);
  WebPAnimDecoderDelete(NULL);
  oracle->AnimDecoderDelete(NULL);

  CHECK(WebPAnimDecoderOptionsInitInternal(&safe_options, WEBP_DEMUX_ABI_VERSION) ==
        1);
  CHECK(oracle->AnimDecoderOptionsInitInternal(&oracle_options,
                                               WEBP_DEMUX_ABI_VERSION) == 1);
  safe_options.color_mode = (WEBP_CSP_MODE)999;
  oracle_options.color_mode = (WEBP_CSP_MODE)999;
  CHECK(WebPAnimDecoderNewInternal(data, &safe_options, WEBP_DEMUX_ABI_VERSION) ==
        NULL);
  CHECK(oracle->AnimDecoderNewInternal(data, &oracle_options,
                                       WEBP_DEMUX_ABI_VERSION) == NULL);

  CHECK(WebPAnimDecoderOptionsInitInternal(&safe_options, WEBP_DEMUX_ABI_VERSION) ==
        1);
  CHECK(oracle->AnimDecoderOptionsInitInternal(&oracle_options,
                                               WEBP_DEMUX_ABI_VERSION) == 1);
  safe_dec = WebPAnimDecoderNewInternal(data, &safe_options, WEBP_DEMUX_ABI_VERSION);
  oracle_dec =
      oracle->AnimDecoderNewInternal(data, &oracle_options, WEBP_DEMUX_ABI_VERSION);
  CHECK(safe_dec != NULL && oracle_dec != NULL);
  CHECK(WebPAnimDecoderGetInfo(safe_dec, NULL) == 0);
  CHECK(oracle->AnimDecoderGetInfo(oracle_dec, NULL) == 0);
  CHECK(WebPAnimDecoderGetNext(safe_dec, NULL, &safe_ts) == 0);
  CHECK(oracle->AnimDecoderGetNext(oracle_dec, NULL, &oracle_ts) == 0);
  CHECK(WebPAnimDecoderHasMoreFrames(safe_dec) ==
        oracle->AnimDecoderHasMoreFrames(oracle_dec));
  CHECK(WebPAnimDecoderGetNext(safe_dec, &safe_buf, NULL) == 0);
  CHECK(oracle->AnimDecoderGetNext(oracle_dec, &oracle_buf, NULL) == 0);
  CHECK(WebPAnimDecoderHasMoreFrames(safe_dec) ==
        oracle->AnimDecoderHasMoreFrames(oracle_dec));
  WebPAnimDecoderDelete(safe_dec);
  oracle->AnimDecoderDelete(oracle_dec);
  return 0;
}

static int RunAnimDecodeTests(OracleApi* oracle, const WebPData* data) {
  WebPAnimDecoderOptions safe_options;
  WebPAnimDecoderOptions oracle_options;
  WebPAnimDecoder *safe_dec = NULL, *oracle_dec = NULL;
  WebPAnimInfo safe_info;
  WebPAnimInfo oracle_info;
  uint8_t *safe_buf = NULL, *oracle_buf = NULL;
  int safe_ts = 0, oracle_ts = 0;
  const size_t canvas_bytes = 4u * 4u * 4u;
  const WebPDemuxer *safe_demux = NULL, *oracle_demux = NULL;

  CHECK(WebPAnimDecoderOptionsInitInternal(NULL, WEBP_DEMUX_ABI_VERSION) == 0);
  CHECK(oracle->AnimDecoderOptionsInitInternal(NULL, WEBP_DEMUX_ABI_VERSION) == 0);
  CHECK(WebPAnimDecoderOptionsInitInternal(&safe_options, WEBP_DEMUX_ABI_VERSION) == 1);
  CHECK(oracle->AnimDecoderOptionsInitInternal(&oracle_options, WEBP_DEMUX_ABI_VERSION) == 1);
  CHECK(safe_options.color_mode == oracle_options.color_mode);
  CHECK(safe_options.use_threads == oracle_options.use_threads);

  safe_dec = WebPAnimDecoderNewInternal(data, &safe_options, WEBP_DEMUX_ABI_VERSION);
  oracle_dec =
      oracle->AnimDecoderNewInternal(data, &oracle_options, WEBP_DEMUX_ABI_VERSION);
  CHECK(safe_dec != NULL && oracle_dec != NULL);
  CHECK(WebPAnimDecoderGetInfo(safe_dec, &safe_info) == 1);
  CHECK(oracle->AnimDecoderGetInfo(oracle_dec, &oracle_info) == 1);
  CHECK(CompareAnimInfo(&safe_info, &oracle_info));
  CHECK(safe_info.canvas_width == 4 && safe_info.canvas_height == 4);
  CHECK(safe_info.frame_count == 3 && safe_info.bgcolor == 0xffffffffu);

  safe_demux = WebPAnimDecoderGetDemuxer(safe_dec);
  oracle_demux = oracle->AnimDecoderGetDemuxer(oracle_dec);
  CHECK(safe_demux != NULL && oracle_demux != NULL);
  CHECK(CompareFeatureSet(safe_demux, oracle_demux, oracle));
  CHECK(CompareChunkByTag(safe_demux, oracle_demux, oracle, "ICCP"));

  while (WebPAnimDecoderHasMoreFrames(safe_dec)) {
    CHECK(oracle->AnimDecoderHasMoreFrames(oracle_dec) == 1);
    CHECK(WebPAnimDecoderGetNext(safe_dec, &safe_buf, &safe_ts) == 1);
    CHECK(oracle->AnimDecoderGetNext(oracle_dec, &oracle_buf, &oracle_ts) == 1);
    CHECK(safe_ts == oracle_ts);
    CHECK(CompareBytes(safe_buf, oracle_buf, canvas_bytes));
  }
  CHECK(oracle->AnimDecoderHasMoreFrames(oracle_dec) == 0);
  CHECK(WebPAnimDecoderHasMoreFrames(safe_dec) == 0);

  WebPAnimDecoderReset(safe_dec);
  oracle->AnimDecoderReset(oracle_dec);
  CHECK(WebPAnimDecoderHasMoreFrames(safe_dec) == 1);
  CHECK(oracle->AnimDecoderHasMoreFrames(oracle_dec) == 1);
  CHECK(WebPAnimDecoderGetNext(safe_dec, &safe_buf, &safe_ts) == 1);
  CHECK(oracle->AnimDecoderGetNext(oracle_dec, &oracle_buf, &oracle_ts) == 1);
  CHECK(safe_ts == oracle_ts);
  CHECK(CompareBytes(safe_buf, oracle_buf, canvas_bytes));

  WebPAnimDecoderDelete(safe_dec);
  oracle->AnimDecoderDelete(oracle_dec);
  return 0;
}

int main(void) {
  OracleApi oracle;
  WebPData data = {kAnimSample, sizeof(kAnimSample)};
  CHECK(LoadOracleApi(&oracle));
  CHECK(RunDemuxTests(&oracle, &data) == 0);
  CHECK(RunRawDemuxTests(&oracle) == 0);
  CHECK(RunInvalidApiTests(&oracle, &data) == 0);
  CHECK(RunAnimDecodeTests(&oracle, &data) == 0);
  UnloadOracleApi(&oracle);
  return 0;
}
