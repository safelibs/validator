#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "webp/decode.h"
#include "webp/encode.h"

#ifndef TEST_LIBRARY_NAME
#define TEST_LIBRARY_NAME "unknown"
#endif

#define CHECK(expr)                                                            \
  do {                                                                         \
    if (!(expr)) {                                                             \
      fprintf(stderr, "[%s] check failed at line %d: %s\n",                    \
              TEST_LIBRARY_NAME, __LINE__, #expr);                             \
      return __LINE__;                                                         \
    }                                                                          \
  } while (0)

static void FillPattern(uint8_t* rgba, int width, int height) {
  int x, y;
  for (y = 0; y < height; ++y) {
    for (x = 0; x < width; ++x) {
      const int offset = 4 * (y * width + x);
      rgba[offset + 0] = (uint8_t)(17 + x * 29 + y * 11);
      rgba[offset + 1] = (uint8_t)(201 - x * 19 - y * 7);
      rgba[offset + 2] = (uint8_t)(33 + x * 13 + y * 23);
      switch ((x + 2 * y) & 3) {
        case 0:
          rgba[offset + 3] = 0;
          break;
        case 1:
          rgba[offset + 3] = 96;
          break;
        case 2:
          rgba[offset + 3] = 192;
          break;
        default:
          rgba[offset + 3] = 255;
          break;
      }
    }
  }
}

static void ConvertPackedBuffers(const uint8_t* rgba, int width, int height,
                                 uint8_t* rgb, uint8_t* bgr, uint8_t* bgra) {
  const size_t pixels = (size_t)width * (size_t)height;
  size_t i;
  for (i = 0; i < pixels; ++i) {
    rgb[3 * i + 0] = rgba[4 * i + 0];
    rgb[3 * i + 1] = rgba[4 * i + 1];
    rgb[3 * i + 2] = rgba[4 * i + 2];

    bgr[3 * i + 0] = rgba[4 * i + 2];
    bgr[3 * i + 1] = rgba[4 * i + 1];
    bgr[3 * i + 2] = rgba[4 * i + 0];

    bgra[4 * i + 0] = rgba[4 * i + 2];
    bgra[4 * i + 1] = rgba[4 * i + 1];
    bgra[4 * i + 2] = rgba[4 * i + 0];
    bgra[4 * i + 3] = rgba[4 * i + 3];
  }
}

static int ImportPictureRGBA(const uint8_t* rgba, int width, int height,
                             WebPPicture* picture) {
  memset(picture, 0, sizeof(*picture));
  if (!WebPPictureInit(picture)) return 0;
  picture->use_argb = 1;
  picture->width = width;
  picture->height = height;
  return WebPPictureImportRGBA(picture, rgba, width * 4);
}

static int EncodeExactLossless(const uint8_t* rgba, int width, int height,
                               uint8_t** output, size_t* output_size) {
  WebPConfig config;
  WebPPicture picture;
  WebPMemoryWriter writer;

  *output = NULL;
  *output_size = 0;
  if (!WebPConfigInit(&config)) return 0;
  if (!WebPConfigLosslessPreset(&config, 6)) return 0;
  config.exact = 1;
  if (!ImportPictureRGBA(rgba, width, height, &picture)) return 0;

  WebPMemoryWriterInit(&writer);
  picture.writer = WebPMemoryWrite;
  picture.custom_ptr = &writer;
  if (!WebPEncode(&config, &picture)) {
    WebPPictureFree(&picture);
    WebPMemoryWriterClear(&writer);
    return 0;
  }

  WebPPictureFree(&picture);
  *output = writer.mem;
  *output_size = writer.size;
  return 1;
}

static int TestMemoryWriter(void) {
  static const uint8_t kChunk1[] = {0x00, 0x11, 0x22};
  static const uint8_t kChunk2[] = {0x33, 0x44, 0x55, 0x66};
  static const uint8_t kExpected[] = {0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66};
  WebPMemoryWriter writer;
  WebPPicture picture;

  memset(&picture, 0, sizeof(picture));
  WebPMemoryWriterInit(&writer);
  CHECK(writer.mem == NULL);
  CHECK(writer.size == 0);
  CHECK(writer.max_size == 0);

  picture.custom_ptr = &writer;
  CHECK(WebPMemoryWrite(kChunk1, sizeof(kChunk1), &picture));
  CHECK(WebPMemoryWrite(kChunk2, sizeof(kChunk2), &picture));
  CHECK(writer.size == sizeof(kExpected));
  CHECK(memcmp(writer.mem, kExpected, sizeof(kExpected)) == 0);

  WebPMemoryWriterClear(&writer);
  CHECK(writer.mem == NULL);
  CHECK(writer.size == 0);
  CHECK(writer.max_size == 0);
  return 0;
}

static int TestPictureAllocators(void) {
  WebPPicture argb;
  WebPPicture yuva;

  memset(&argb, 0, sizeof(argb));
  CHECK(WebPPictureInit(&argb));
  argb.use_argb = 1;
  argb.width = 7;
  argb.height = 5;
  CHECK(WebPPictureAlloc(&argb));
  CHECK(argb.argb != NULL);
  CHECK(argb.argb_stride == argb.width);
  CHECK(argb.y == NULL);
  CHECK(argb.u == NULL);
  CHECK(argb.v == NULL);
  CHECK(argb.a == NULL);
  WebPPictureFree(&argb);
  CHECK(argb.argb == NULL);

  memset(&yuva, 0, sizeof(yuva));
  CHECK(WebPPictureInit(&yuva));
  yuva.use_argb = 0;
  yuva.colorspace = WEBP_YUV420A;
  yuva.width = 7;
  yuva.height = 5;
  CHECK(WebPPictureAlloc(&yuva));
  CHECK(yuva.y != NULL);
  CHECK(yuva.u != NULL);
  CHECK(yuva.v != NULL);
  CHECK(yuva.a != NULL);
  CHECK(yuva.y_stride == yuva.width);
  CHECK(yuva.uv_stride == 4);
  CHECK(yuva.a_stride == yuva.width);
  CHECK(yuva.argb == NULL);
  WebPPictureFree(&yuva);
  CHECK(yuva.y == NULL);
  CHECK(yuva.u == NULL);
  CHECK(yuva.v == NULL);
  CHECK(yuva.a == NULL);
  return 0;
}

static int TestConfigAndPictureUtilities(void) {
  enum { kWidth = 4, kHeight = 3 };
  uint8_t rgba[kWidth * kHeight * 4];
  WebPConfig config;
  WebPPicture source;
  WebPPicture view;
  WebPPicture derived;
  uint8_t* encoded = NULL;
  size_t encoded_size = 0;
  uint8_t* decoded = NULL;
  int width = 0;
  int height = 0;

  FillPattern(rgba, kWidth, kHeight);

  CHECK(WebPConfigPreset(&config, WEBP_PRESET_PHOTO, 82.0f));
  CHECK(WebPValidateConfig(&config));
  config.segments = 0;
  CHECK(!WebPValidateConfig(&config));
  CHECK(WebPConfigInit(&config));
  CHECK(WebPConfigLosslessPreset(&config, 6));
  CHECK(!WebPConfigLosslessPreset(&config, -1));
  CHECK(WebPConfigInit(&config));
  CHECK(WebPConfigLosslessPreset(&config, 6));
  config.exact = 1;
  CHECK(WebPValidateConfig(&config));

  CHECK(ImportPictureRGBA(rgba, kWidth, kHeight, &source));
  CHECK(WebPPictureHasTransparency(&source));

  memset(&view, 0, sizeof(view));
  CHECK(WebPPictureView(&source, 1, 0, 3, 3, &view));
  CHECK(WebPPictureIsView(&view));
  CHECK(view.width == 3);
  CHECK(view.height == 3);

  memset(&derived, 0, sizeof(derived));
  CHECK(WebPPictureCopy(&view, &derived));
  CHECK(!WebPPictureIsView(&derived));
  WebPPictureFree(&view);
  CHECK(source.argb != NULL);

  CHECK(WebPPictureCrop(&derived, 1, 1, 2, 2));
  CHECK(WebPPictureRescale(&derived, 0, 4));
  CHECK(derived.width == 4);
  CHECK(derived.height == 4);
  CHECK(WebPPictureHasTransparency(&derived));
  CHECK(WebPPictureARGBToYUVA(&derived, WEBP_YUV420));
  CHECK(!derived.use_argb);
  CHECK(WebPPictureYUVAToARGB(&derived));
  CHECK(derived.use_argb);
  WebPBlendAlpha(&derived, 0x00112233u);
  CHECK(!WebPPictureHasTransparency(&derived));

  CHECK(EncodeExactLossless(rgba, kWidth, kHeight, &encoded, &encoded_size));
  CHECK(WebPGetInfo(encoded, encoded_size, &width, &height));
  CHECK(width == kWidth);
  CHECK(height == kHeight);

  decoded = WebPDecodeRGBA(encoded, encoded_size, &width, &height);
  CHECK(decoded != NULL);
  CHECK(width == kWidth);
  CHECK(height == kHeight);
  CHECK(memcmp(decoded, rgba, sizeof(rgba)) == 0);

  WebPFree(decoded);
  WebPFree(encoded);
  WebPPictureFree(&derived);
  WebPPictureFree(&source);
  return 0;
}

static int CheckLosslessRGBAHelper(const uint8_t* rgba, int width, int height) {
  uint8_t* encoded = NULL;
  uint8_t* decoded = NULL;
  int decoded_width = 0;
  int decoded_height = 0;
  size_t encoded_size =
      WebPEncodeLosslessRGBA(rgba, width, height, width * 4, &encoded);
  CHECK(encoded_size > 0);
  CHECK(encoded != NULL);

  decoded = WebPDecodeRGBA(encoded, encoded_size, &decoded_width, &decoded_height);
  CHECK(decoded != NULL);
  CHECK(decoded_width == width);
  CHECK(decoded_height == height);
  CHECK(memcmp(decoded, rgba, (size_t)width * (size_t)height * 4u) == 0);

  WebPFree(decoded);
  WebPFree(encoded);
  return 0;
}

static int CheckLosslessRGBHelper(int mode, const uint8_t* packed, const uint8_t* expected,
                                  int width, int height, int stride) {
  uint8_t* encoded = NULL;
  uint8_t* decoded = NULL;
  int decoded_width = 0;
  int decoded_height = 0;
  size_t encoded_size = 0;

  switch (mode) {
    case 0:
      encoded_size = WebPEncodeLosslessRGB(packed, width, height, stride, &encoded);
      decoded = WebPDecodeRGB(encoded, encoded_size, &decoded_width, &decoded_height);
      break;
    case 1:
      encoded_size = WebPEncodeLosslessBGR(packed, width, height, stride, &encoded);
      decoded = WebPDecodeBGR(encoded, encoded_size, &decoded_width, &decoded_height);
      break;
    default:
      encoded_size = WebPEncodeLosslessBGRA(packed, width, height, stride, &encoded);
      decoded = WebPDecodeBGRA(encoded, encoded_size, &decoded_width, &decoded_height);
      break;
  }

  CHECK(encoded_size > 0);
  CHECK(encoded != NULL);
  CHECK(decoded != NULL);
  CHECK(decoded_width == width);
  CHECK(decoded_height == height);
  CHECK(memcmp(decoded, expected,
               (size_t)width * (size_t)height * (size_t)(mode == 2 ? 4 : 3)) == 0);

  WebPFree(decoded);
  WebPFree(encoded);
  return 0;
}

static int CheckLossyHelpers(const uint8_t* rgb, const uint8_t* rgba,
                             const uint8_t* bgr, const uint8_t* bgra,
                             int width, int height) {
  uint8_t* encoded = NULL;
  size_t encoded_size;
  int decoded_width = 0;
  int decoded_height = 0;

  encoded_size = WebPEncodeRGB(rgb, width, height, width * 3, 75.0f, &encoded);
  CHECK(encoded_size > 0);
  CHECK(WebPGetInfo(encoded, encoded_size, &decoded_width, &decoded_height));
  CHECK(decoded_width == width);
  CHECK(decoded_height == height);
  WebPFree(encoded);

  encoded_size = WebPEncodeRGBA(rgba, width, height, width * 4, 75.0f, &encoded);
  CHECK(encoded_size > 0);
  CHECK(WebPGetInfo(encoded, encoded_size, &decoded_width, &decoded_height));
  CHECK(decoded_width == width);
  CHECK(decoded_height == height);
  WebPFree(encoded);

  encoded_size = WebPEncodeBGR(bgr, width, height, width * 3, 75.0f, &encoded);
  CHECK(encoded_size > 0);
  CHECK(WebPGetInfo(encoded, encoded_size, &decoded_width, &decoded_height));
  CHECK(decoded_width == width);
  CHECK(decoded_height == height);
  WebPFree(encoded);

  encoded_size = WebPEncodeBGRA(bgra, width, height, width * 4, 75.0f, &encoded);
  CHECK(encoded_size > 0);
  CHECK(WebPGetInfo(encoded, encoded_size, &decoded_width, &decoded_height));
  CHECK(decoded_width == width);
  CHECK(decoded_height == height);
  WebPFree(encoded);

  return 0;
}

static int TestEncodeHelpers(void) {
  enum { kWidth = 5, kHeight = 4 };
  uint8_t rgba[kWidth * kHeight * 4];
  uint8_t opaque_rgba[kWidth * kHeight * 4];
  uint8_t rgb[kWidth * kHeight * 3];
  uint8_t bgr[kWidth * kHeight * 3];
  uint8_t bgra[kWidth * kHeight * 4];
  size_t i;

  FillPattern(rgba, kWidth, kHeight);
  memcpy(opaque_rgba, rgba, sizeof(opaque_rgba));
  for (i = 0; i < (size_t)kWidth * (size_t)kHeight; ++i) {
    opaque_rgba[4 * i + 3] = 255;
  }
  ConvertPackedBuffers(opaque_rgba, kWidth, kHeight, rgb, bgr, bgra);

  CHECK(CheckLosslessRGBAHelper(opaque_rgba, kWidth, kHeight) == 0);
  CHECK(CheckLosslessRGBHelper(0, rgb, rgb, kWidth, kHeight, kWidth * 3) == 0);
  CHECK(CheckLosslessRGBHelper(1, bgr, bgr, kWidth, kHeight, kWidth * 3) == 0);
  CHECK(CheckLosslessRGBHelper(2, bgra, bgra, kWidth, kHeight, kWidth * 4) == 0);
  CHECK(CheckLossyHelpers(rgb, opaque_rgba, bgr, bgra, kWidth, kHeight) == 0);
  return 0;
}

int main(void) {
  int result = 0;

  result = TestMemoryWriter();
  if (result != 0) return result;

  result = TestPictureAllocators();
  if (result != 0) return result;

  result = TestConfigAndPictureUtilities();
  if (result != 0) return result;

  result = TestEncodeHelpers();
  if (result != 0) return result;

  fprintf(stderr, "[%s] encode API checks passed\n", TEST_LIBRARY_NAME);
  return 0;
}
