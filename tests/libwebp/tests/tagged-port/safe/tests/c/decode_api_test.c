#define _GNU_SOURCE 1
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dlfcn.h>

#include "webp/decode.h"

#ifndef TEST_WEBP_PATH
#define TEST_WEBP_PATH ""
#endif

#ifndef TEST_PPM_PATH
#define TEST_PPM_PATH ""
#endif

#ifndef TEST_LIBRARY_NAME
#define TEST_LIBRARY_NAME "unknown"
#endif

#ifndef ORACLE_LIBRARY_PATH
#define ORACLE_LIBRARY_PATH ""
#endif

int VP8CheckSignature(const uint8_t* data, size_t data_size);
int VP8GetInfo(const uint8_t* data, size_t data_size, size_t chunk_size,
               int* width, int* height);

#define CHECK(expr)                                                            \
  do {                                                                         \
    if (!(expr)) {                                                             \
      fprintf(stderr, "[%s] check failed at line %d: %s\n",                    \
              TEST_LIBRARY_NAME, __LINE__, #expr);                             \
      return __LINE__;                                                         \
    }                                                                          \
  } while (0)

static uint32_t ReadLE32(const uint8_t* bytes) {
  return ((uint32_t)bytes[0]) | ((uint32_t)bytes[1] << 8) |
         ((uint32_t)bytes[2] << 16) | ((uint32_t)bytes[3] << 24);
}

static int ReadFile(const char* path, uint8_t** data, size_t* size) {
  FILE* file = fopen(path, "rb");
  long file_size;
  size_t read_size;
  uint8_t* buffer;
  if (file == NULL) return 0;
  if (fseek(file, 0, SEEK_END) != 0) {
    fclose(file);
    return 0;
  }
  file_size = ftell(file);
  if (file_size < 0 || fseek(file, 0, SEEK_SET) != 0) {
    fclose(file);
    return 0;
  }
  buffer = (uint8_t*)malloc((size_t)file_size);
  if (buffer == NULL) {
    fclose(file);
    return 0;
  }
  read_size = fread(buffer, 1, (size_t)file_size, file);
  fclose(file);
  if (read_size != (size_t)file_size) {
    free(buffer);
    return 0;
  }
  *data = buffer;
  *size = (size_t)file_size;
  return 1;
}

static int ReadPPM(const char* path, uint8_t** pixels, int* width, int* height) {
  FILE* file = fopen(path, "rb");
  int max_value = 0;
  size_t pixel_count;
  uint8_t* buffer;
  int separator;
  if (file == NULL) return 0;
  if (fscanf(file, "P6 %d %d %d", width, height, &max_value) != 3 ||
      max_value != 255 || *width <= 0 || *height <= 0) {
    fclose(file);
    return 0;
  }
  separator = fgetc(file);
  if (separator == EOF) {
    fclose(file);
    return 0;
  }
  pixel_count = (size_t)(*width) * (size_t)(*height) * 3u;
  buffer = (uint8_t*)malloc(pixel_count);
  if (buffer == NULL) {
    fclose(file);
    return 0;
  }
  if (fread(buffer, 1, pixel_count, file) != pixel_count) {
    free(buffer);
    fclose(file);
    return 0;
  }
  fclose(file);
  *pixels = buffer;
  return 1;
}

static int FindChunk(const uint8_t* webp_data, size_t webp_size, const char* tag,
                     const uint8_t** chunk_data, size_t* chunk_size) {
  size_t offset = 12;
  if (webp_size < 12 || memcmp(webp_data, "RIFF", 4) != 0 ||
      memcmp(webp_data + 8, "WEBP", 4) != 0) {
    return 0;
  }
  while (offset + 8 <= webp_size) {
    uint32_t payload_size = ReadLE32(webp_data + offset + 4);
    size_t padded_size = (size_t)payload_size + ((size_t)payload_size & 1u);
    if (offset + 8 + padded_size > webp_size) return 0;
    if (memcmp(webp_data + offset, tag, 4) == 0) {
      *chunk_data = webp_data + offset + 8;
      *chunk_size = (size_t)payload_size;
      return 1;
    }
    offset += 8 + padded_size;
  }
  return 0;
}

static int CompareRGB(const uint8_t* expected_rgb, const uint8_t* actual_rgb,
                      int width, int height, int order) {
  const size_t pixels = (size_t)width * (size_t)height;
  size_t i;
  for (i = 0; i < pixels; ++i) {
    const uint8_t r = expected_rgb[3 * i + 0];
    const uint8_t g = expected_rgb[3 * i + 1];
    const uint8_t b = expected_rgb[3 * i + 2];
    if (order == 0) {
      if (actual_rgb[3 * i + 0] != r || actual_rgb[3 * i + 1] != g ||
          actual_rgb[3 * i + 2] != b) {
        return 0;
      }
    } else {
      if (actual_rgb[3 * i + 0] != b || actual_rgb[3 * i + 1] != g ||
          actual_rgb[3 * i + 2] != r) {
        return 0;
      }
    }
  }
  return 1;
}

static int CompareRGBA(const uint8_t* expected_rgb, const uint8_t* actual_rgba,
                       int width, int height, int order) {
  const size_t pixels = (size_t)width * (size_t)height;
  size_t i;
  for (i = 0; i < pixels; ++i) {
    const uint8_t r = expected_rgb[3 * i + 0];
    const uint8_t g = expected_rgb[3 * i + 1];
    const uint8_t b = expected_rgb[3 * i + 2];
    if (order == 0) {
      if (actual_rgba[4 * i + 0] != r || actual_rgba[4 * i + 1] != g ||
          actual_rgba[4 * i + 2] != b || actual_rgba[4 * i + 3] != 255) {
        return 0;
      }
    } else if (order == 1) {
      if (actual_rgba[4 * i + 0] != b || actual_rgba[4 * i + 1] != g ||
          actual_rgba[4 * i + 2] != r || actual_rgba[4 * i + 3] != 255) {
        return 0;
      }
    } else {
      if (actual_rgba[4 * i + 0] != 255 || actual_rgba[4 * i + 1] != r ||
          actual_rgba[4 * i + 2] != g || actual_rgba[4 * i + 3] != b) {
        return 0;
      }
    }
  }
  return 1;
}

static int ComparePlane(const uint8_t* expected, int expected_stride,
                        const uint8_t* actual, int actual_stride, int width,
                        int height) {
  int y;
  for (y = 0; y < height; ++y) {
    if (memcmp(expected + (size_t)y * (size_t)expected_stride,
               actual + (size_t)y * (size_t)actual_stride,
               (size_t)width) != 0) {
      return 0;
    }
  }
  return 1;
}

static int AllBytesEqual(const uint8_t* data, size_t size, uint8_t value) {
  size_t i;
  for (i = 0; i < size; ++i) {
    if (data[i] != value) return 0;
  }
  return 1;
}

typedef uint8_t* (*DecodeFn)(const uint8_t*, size_t, int*, int*);
typedef uint8_t* (*DecodeYUVFn)(const uint8_t*, size_t, int*, int*, uint8_t**, uint8_t**, int*, int*);
typedef void (*WebPFreeFn)(void*);

typedef struct {
  void* handle;
  DecodeFn DecodeRGB;
  DecodeFn DecodeBGR;
  DecodeFn DecodeRGBA;
  DecodeFn DecodeBGRA;
  DecodeFn DecodeARGB;
  DecodeYUVFn DecodeYUV;
  WebPFreeFn Free;
} OracleApi;

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
  LOAD_ORACLE(WebPDecodeRGB, DecodeRGB, DecodeFn);
  LOAD_ORACLE(WebPDecodeBGR, DecodeBGR, DecodeFn);
  LOAD_ORACLE(WebPDecodeRGBA, DecodeRGBA, DecodeFn);
  LOAD_ORACLE(WebPDecodeBGRA, DecodeBGRA, DecodeFn);
  LOAD_ORACLE(WebPDecodeARGB, DecodeARGB, DecodeFn);
  LOAD_ORACLE(WebPDecodeYUV, DecodeYUV, DecodeYUVFn);
  api->Free = (WebPFreeFn)dlsym(api->handle, "WebPFree");
  if (api->Free == NULL) {
    fprintf(stderr, "[%s] missing oracle symbol WebPFree: %s\n",
            TEST_LIBRARY_NAME, dlerror());
    return 0;
  }
#undef LOAD_ORACLE
  return 1;
}

static void UnloadOracleApi(OracleApi* api) {
  if (api->handle != NULL) {
    dlclose(api->handle);
    api->handle = NULL;
  }
}

static int RunDecodeApiTest(void) {
  OracleApi oracle;
  uint8_t* webp_data = NULL;
  size_t webp_size = 0;
  uint8_t* ppm_pixels = NULL;
  int ppm_width = 0;
  int ppm_height = 0;
  const uint8_t* vp8_chunk = NULL;
  size_t vp8_chunk_size = 0;
  WebPBitstreamFeatures features;
  WebPDecoderConfig config;
  WebPDecBuffer output_buffer;
  int width = 0, height = 0;
  uint8_t *rgb = NULL, *bgr = NULL, *rgba = NULL, *bgra = NULL, *argb = NULL;
  uint8_t *oracle_rgb = NULL, *oracle_bgr = NULL, *oracle_rgba = NULL;
  uint8_t *oracle_bgra = NULL, *oracle_argb = NULL;
  uint8_t *rgba_into = NULL, *bgra_into = NULL, *argb_into = NULL;
  uint8_t *rgb_into = NULL, *bgr_into = NULL;
  uint8_t *y = NULL, *u = NULL, *v = NULL;
  uint8_t *oracle_y = NULL, *oracle_u = NULL, *oracle_v = NULL;
  int y_stride = 0, uv_stride = 0;
  int oracle_y_stride = 0, oracle_uv_stride = 0;
  int uv_width = 0, uv_height = 0;
  size_t y_size = 0, uv_size = 0;
  uint8_t *y_into = NULL, *u_into = NULL, *v_into = NULL;
  uint8_t *config_rgba = NULL;
  uint8_t *incremental_rgba = NULL, *generic_rgba = NULL;
  uint8_t *yuva_y = NULL, *yuva_u = NULL, *yuva_v = NULL, *yuva_a = NULL;
  WebPIDecoder* idec = NULL;
  const WebPDecBuffer* visible = NULL;
  uint8_t *incremental_view = NULL, *generic_view = NULL, *yuva_view = NULL;
  uint8_t *yuva_u_view = NULL, *yuva_v_view = NULL, *yuva_a_view = NULL;
  int last_y = 0, visible_left = 0, visible_top = 0, visible_width = 0, visible_height = 0;
  int incremental_stride = 0, generic_stride = 0;
  int yuva_width = 0, yuva_height = 0, yuva_stride = 0, yuva_uv_stride = 0, yuva_a_stride = 0;
  VP8StatusCode status;

  CHECK(ReadFile(TEST_WEBP_PATH, &webp_data, &webp_size));
  CHECK(ReadPPM(TEST_PPM_PATH, &ppm_pixels, &ppm_width, &ppm_height));
  CHECK(LoadOracleApi(&oracle));
  CHECK(FindChunk(webp_data, webp_size, "VP8 ", &vp8_chunk, &vp8_chunk_size));

  CHECK(WebPInitDecBufferInternal(NULL, WEBP_DECODER_ABI_VERSION) == 0);
  CHECK(WebPInitDecoderConfigInternal(NULL, WEBP_DECODER_ABI_VERSION) == 0);
  CHECK(WebPGetInfo(webp_data, webp_size, &width, &height) == 1);
  CHECK(width == ppm_width && height == ppm_height);
  CHECK(WebPGetInfo(webp_data, 1, &width, &height) == 0);
  CHECK(WebPGetFeaturesInternal(webp_data, webp_size, &features,
                                WEBP_DECODER_ABI_VERSION) == VP8_STATUS_OK);
  CHECK(features.width == ppm_width && features.height == ppm_height);
  CHECK(features.has_alpha == 0 && features.has_animation == 0);
  CHECK(WebPGetFeaturesInternal(webp_data, 1, &features,
                                WEBP_DECODER_ABI_VERSION) ==
        VP8_STATUS_NOT_ENOUGH_DATA);
  CHECK(VP8CheckSignature(vp8_chunk + 3, vp8_chunk_size - 3) == 1);
  CHECK(VP8GetInfo(vp8_chunk, vp8_chunk_size, vp8_chunk_size, &width, &height) == 1);
  CHECK(width == ppm_width && height == ppm_height);

  rgb = WebPDecodeRGB(webp_data, webp_size, &width, &height);
  oracle_rgb = oracle.DecodeRGB(webp_data, webp_size, &width, &height);
  CHECK(rgb != NULL && width == ppm_width && height == ppm_height);
  CHECK(oracle_rgb != NULL);
  CHECK(memcmp(oracle_rgb, rgb, (size_t)width * (size_t)height * 3u) == 0);
  bgr = WebPDecodeBGR(webp_data, webp_size, &width, &height);
  oracle_bgr = oracle.DecodeBGR(webp_data, webp_size, &width, &height);
  CHECK(bgr != NULL);
  CHECK(oracle_bgr != NULL);
  CHECK(memcmp(oracle_bgr, bgr, (size_t)width * (size_t)height * 3u) == 0);
  rgba = WebPDecodeRGBA(webp_data, webp_size, &width, &height);
  oracle_rgba = oracle.DecodeRGBA(webp_data, webp_size, &width, &height);
  CHECK(rgba != NULL);
  CHECK(oracle_rgba != NULL);
  CHECK(memcmp(oracle_rgba, rgba, (size_t)width * (size_t)height * 4u) == 0);
  bgra = WebPDecodeBGRA(webp_data, webp_size, &width, &height);
  oracle_bgra = oracle.DecodeBGRA(webp_data, webp_size, &width, &height);
  CHECK(bgra != NULL);
  CHECK(oracle_bgra != NULL);
  CHECK(memcmp(oracle_bgra, bgra, (size_t)width * (size_t)height * 4u) == 0);
  argb = WebPDecodeARGB(webp_data, webp_size, &width, &height);
  oracle_argb = oracle.DecodeARGB(webp_data, webp_size, &width, &height);
  CHECK(argb != NULL);
  CHECK(oracle_argb != NULL);
  CHECK(memcmp(oracle_argb, argb, (size_t)width * (size_t)height * 4u) == 0);
  CHECK(WebPDecodeRGBA(NULL, webp_size, &width, &height) == NULL);

  rgba_into = (uint8_t*)malloc((size_t)width * (size_t)height * 4u);
  bgra_into = (uint8_t*)malloc((size_t)width * (size_t)height * 4u);
  argb_into = (uint8_t*)malloc((size_t)width * (size_t)height * 4u);
  rgb_into = (uint8_t*)malloc((size_t)width * (size_t)height * 3u);
  bgr_into = (uint8_t*)malloc((size_t)width * (size_t)height * 3u);
  CHECK(rgba_into != NULL && bgra_into != NULL && argb_into != NULL &&
        rgb_into != NULL && bgr_into != NULL);
  CHECK(WebPDecodeRGBAInto(webp_data, webp_size, rgba_into,
                           (size_t)width * (size_t)height * 4u, width * 4) == rgba_into);
  CHECK(WebPDecodeBGRAInto(webp_data, webp_size, bgra_into,
                           (size_t)width * (size_t)height * 4u, width * 4) == bgra_into);
  CHECK(WebPDecodeARGBInto(webp_data, webp_size, argb_into,
                           (size_t)width * (size_t)height * 4u, width * 4) == argb_into);
  CHECK(WebPDecodeRGBInto(webp_data, webp_size, rgb_into,
                          (size_t)width * (size_t)height * 3u, width * 3) == rgb_into);
  CHECK(WebPDecodeBGRInto(webp_data, webp_size, bgr_into,
                          (size_t)width * (size_t)height * 3u, width * 3) == bgr_into);
  CHECK(memcmp(rgba, rgba_into, (size_t)width * (size_t)height * 4u) == 0);
  CHECK(memcmp(bgra, bgra_into, (size_t)width * (size_t)height * 4u) == 0);
  CHECK(memcmp(argb, argb_into, (size_t)width * (size_t)height * 4u) == 0);
  CHECK(memcmp(rgb, rgb_into, (size_t)width * (size_t)height * 3u) == 0);
  CHECK(memcmp(bgr, bgr_into, (size_t)width * (size_t)height * 3u) == 0);

  y = WebPDecodeYUV(webp_data, webp_size, &width, &height, &u, &v, &y_stride, &uv_stride);
  oracle_y = oracle.DecodeYUV(webp_data, webp_size, &width, &height,
                              &oracle_u, &oracle_v,
                              &oracle_y_stride, &oracle_uv_stride);
  CHECK(y != NULL);
  CHECK(oracle_y != NULL);
  uv_width = (width + 1) / 2;
  uv_height = (height + 1) / 2;
  y_size = (size_t)width * (size_t)height;
  uv_size = (size_t)uv_width * (size_t)uv_height;
  CHECK(ComparePlane(oracle_y, oracle_y_stride, y, y_stride, width, height));
  CHECK(ComparePlane(oracle_u, oracle_uv_stride, u, uv_stride, uv_width, uv_height));
  CHECK(ComparePlane(oracle_v, oracle_uv_stride, v, uv_stride, uv_width, uv_height));
  y_into = (uint8_t*)malloc(y_size);
  u_into = (uint8_t*)malloc(uv_size);
  v_into = (uint8_t*)malloc(uv_size);
  CHECK(y_into != NULL && u_into != NULL && v_into != NULL);
  CHECK(WebPDecodeYUVInto(webp_data, webp_size,
                          y_into, y_size, width,
                          u_into, uv_size, uv_width,
                          v_into, uv_size, uv_width) == y_into);
  CHECK(ComparePlane(y, y_stride, y_into, width, width, height));
  CHECK(ComparePlane(u, uv_stride, u_into, uv_width, uv_width, uv_height));
  CHECK(ComparePlane(v, uv_stride, v_into, uv_width, uv_width, uv_height));

  CHECK(WebPInitDecoderConfig(&config));
  memset(&output_buffer, 0, sizeof(output_buffer));
  CHECK(WebPInitDecBuffer(&output_buffer));
  config_rgba = (uint8_t*)malloc((size_t)width * (size_t)height * 4u);
  CHECK(config_rgba != NULL);
  config.output.colorspace = MODE_RGBA;
  config.output.is_external_memory = 1;
  config.output.u.RGBA.rgba = config_rgba;
  config.output.u.RGBA.stride = width * 4;
  config.output.u.RGBA.size = (size_t)width * (size_t)height * 4u;
  CHECK(WebPDecode(webp_data, webp_size, &config) == VP8_STATUS_OK);
  CHECK(memcmp(config_rgba, rgba, (size_t)width * (size_t)height * 4u) == 0);
  CHECK(WebPDecode(webp_data, 1, &config) == VP8_STATUS_BITSTREAM_ERROR);
  WebPFreeDecBuffer(&config.output);

  incremental_rgba = (uint8_t*)malloc((size_t)width * (size_t)height * 4u);
  CHECK(incremental_rgba != NULL);
  idec = WebPINewRGB(MODE_RGBA, incremental_rgba,
                     (size_t)width * (size_t)height * 4u, width * 4);
  CHECK(idec != NULL);
  status = WebPIAppend(idec, webp_data, 1);
  CHECK(status == VP8_STATUS_SUSPENDED || status == VP8_STATUS_OK);
  if (webp_size > 1) {
    CHECK(WebPIAppend(idec, webp_data + 1, webp_size - 1) == VP8_STATUS_OK);
  }
  incremental_view = WebPIDecGetRGB(idec, &last_y, &width, &height, &incremental_stride);
  CHECK(incremental_view == incremental_rgba);
  CHECK(last_y == height && incremental_stride == width * 4);
  CHECK(memcmp(incremental_view, rgba, (size_t)width * (size_t)height * 4u) == 0);
  visible = WebPIDecodedArea(idec, &visible_left, &visible_top,
                             &visible_width, &visible_height);
  CHECK(visible != NULL);
  CHECK(visible_left == 0 && visible_top == 0);
  CHECK(visible_width == width && visible_height == height);
  WebPIDelete(idec);
  idec = NULL;

  generic_rgba = (uint8_t*)malloc((size_t)width * (size_t)height * 4u);
  CHECK(generic_rgba != NULL);
  CHECK(WebPInitDecBuffer(&output_buffer));
  output_buffer.colorspace = MODE_RGBA;
  output_buffer.is_external_memory = 1;
  output_buffer.u.RGBA.rgba = generic_rgba;
  output_buffer.u.RGBA.stride = width * 4;
  output_buffer.u.RGBA.size = (size_t)width * (size_t)height * 4u;
  idec = WebPINewDecoder(&output_buffer);
  CHECK(idec != NULL);
  status = WebPIUpdate(idec, webp_data, webp_size / 2);
  CHECK(status == VP8_STATUS_SUSPENDED || status == VP8_STATUS_OK);
  CHECK(WebPIUpdate(idec, webp_data, webp_size) == VP8_STATUS_OK);
  generic_view = WebPIDecGetRGB(idec, &last_y, &width, &height, &generic_stride);
  CHECK(generic_view == generic_rgba);
  CHECK(last_y == height && generic_stride == width * 4);
  CHECK(memcmp(generic_view, rgba, (size_t)width * (size_t)height * 4u) == 0);
  WebPIDelete(idec);
  idec = NULL;

  yuva_y = (uint8_t*)malloc(y_size);
  yuva_u = (uint8_t*)malloc(uv_size);
  yuva_v = (uint8_t*)malloc(uv_size);
  yuva_a = (uint8_t*)malloc(y_size);
  CHECK(yuva_y != NULL && yuva_u != NULL && yuva_v != NULL && yuva_a != NULL);
  idec = WebPINewYUVA(yuva_y, y_size, width,
                      yuva_u, uv_size, uv_width,
                      yuva_v, uv_size, uv_width,
                      yuva_a, y_size, width);
  CHECK(idec != NULL);
  status = WebPIUpdate(idec, webp_data, webp_size / 2);
  CHECK(status == VP8_STATUS_SUSPENDED || status == VP8_STATUS_OK);
  CHECK(WebPIUpdate(idec, webp_data, webp_size) == VP8_STATUS_OK);
  yuva_view = WebPIDecGetYUVA(idec, &last_y, &yuva_u_view, &yuva_v_view, &yuva_a_view,
                              &yuva_width, &yuva_height, &yuva_stride,
                              &yuva_uv_stride, &yuva_a_stride);
  CHECK(yuva_view == yuva_y);
  CHECK(yuva_u_view == yuva_u && yuva_v_view == yuva_v);
  CHECK(yuva_a_view == yuva_a);
  CHECK(last_y == yuva_height && yuva_width == width && yuva_height == height);
  CHECK(yuva_stride == width && yuva_uv_stride == uv_width && yuva_a_stride == width);
  CHECK(ComparePlane(y, y_stride, yuva_y, width, width, height));
  CHECK(ComparePlane(u, uv_stride, yuva_u, uv_width, uv_width, uv_height));
  CHECK(ComparePlane(v, uv_stride, yuva_v, uv_width, uv_width, uv_height));
  CHECK(AllBytesEqual(yuva_a, y_size, 0xff));
  WebPIDelete(idec);
  idec = NULL;

  idec = WebPINewYUV(yuva_y, y_size, width, yuva_u, uv_size, uv_width,
                     yuva_v, uv_size, uv_width);
  CHECK(idec != NULL);
  WebPIDelete(idec);
  idec = NULL;

  WebPFree(rgb);
  WebPFree(bgr);
  WebPFree(rgba);
  WebPFree(bgra);
  WebPFree(argb);
  WebPFree(y);
  oracle.Free(oracle_rgb);
  oracle.Free(oracle_bgr);
  oracle.Free(oracle_rgba);
  oracle.Free(oracle_bgra);
  oracle.Free(oracle_argb);
  oracle.Free(oracle_y);
  free(rgba_into);
  free(bgra_into);
  free(argb_into);
  free(rgb_into);
  free(bgr_into);
  free(y_into);
  free(u_into);
  free(v_into);
  free(config_rgba);
  free(incremental_rgba);
  free(generic_rgba);
  free(yuva_y);
  free(yuva_u);
  free(yuva_v);
  free(yuva_a);
  free(ppm_pixels);
  free(webp_data);
  UnloadOracleApi(&oracle);
  return 0;
}

int main(void) {
  return RunDecodeApiTest();
}
