// Copyright 2026
//
// Public API regression tests for libwebp.

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "src/webp/decode.h"
#include "src/webp/demux.h"
#include "src/webp/encode.h"
#include "src/webp/mux.h"

#define ASSERT_TRUE(expr)                                                     \
  do {                                                                        \
    if (!(expr)) {                                                            \
      fprintf(stderr, "%s:%d: assertion failed: %s\n", __FILE__, __LINE__,    \
              #expr);                                                         \
      return 0;                                                               \
    }                                                                         \
  } while (0)

#define ASSERT_INT_EQ(expected, actual)                                       \
  do {                                                                        \
    const int actual_value = (actual);                                        \
    const int expected_value = (expected);                                    \
    if (actual_value != expected_value) {                                     \
      fprintf(stderr,                                                          \
              "%s:%d: expected %s == %d, got %d\n", __FILE__, __LINE__,       \
              #actual, expected_value, actual_value);                         \
      return 0;                                                               \
    }                                                                         \
  } while (0)

#define ASSERT_UINT32_EQ(expected, actual)                                    \
  do {                                                                        \
    const uint32_t actual_value = (actual);                                   \
    const uint32_t expected_value = (expected);                               \
    if (actual_value != expected_value) {                                     \
      fprintf(stderr,                                                          \
              "%s:%d: expected %s == 0x%08x, got 0x%08x\n", __FILE__,         \
              __LINE__, #actual, expected_value, actual_value);               \
      return 0;                                                               \
    }                                                                         \
  } while (0)

#define ASSERT_SIZE_EQ(expected, actual)                                      \
  do {                                                                        \
    const size_t actual_value = (actual);                                     \
    const size_t expected_value = (expected);                                 \
    if (actual_value != expected_value) {                                     \
      fprintf(stderr,                                                          \
              "%s:%d: expected %s == %zu, got %zu\n", __FILE__, __LINE__,     \
              #actual, expected_value, actual_value);                         \
      return 0;                                                               \
    }                                                                         \
  } while (0)

#define ASSERT_MEM_EQ(expected, actual, size)                                 \
  do {                                                                        \
    const size_t compare_size = (size);                                       \
    if (memcmp((expected), (actual), compare_size) != 0) {                    \
      fprintf(stderr, "%s:%d: memory comparison failed: %s\n", __FILE__,      \
              __LINE__, #actual);                                             \
      return 0;                                                               \
    }                                                                         \
  } while (0)

static void FillPattern(uint8_t* rgba, int width, int height, int variant) {
  int x, y;
  for (y = 0; y < height; ++y) {
    for (x = 0; x < width; ++x) {
      const int offset = 4 * (y * width + x);
      rgba[offset + 0] = (uint8_t)(20 + variant * 9 + x * 37 + y * 11);
      rgba[offset + 1] = (uint8_t)(220 - variant * 7 - x * 31 - y * 13);
      rgba[offset + 2] = (uint8_t)(15 + variant * 5 + x * 19 + y * 29);
      switch ((x + 2 * y + variant) & 3) {
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

static int ImportPicture(const uint8_t* rgba, int width, int height,
                         WebPPicture* picture) {
  if (!WebPPictureInit(picture)) return 0;
  picture->use_argb = 1;
  picture->width = width;
  picture->height = height;
  return WebPPictureImportRGBA(picture, rgba, width * 4);
}

static int EncodeExactLossless(const uint8_t* rgba, int width, int height,
                               WebPData* output) {
  WebPConfig config;
  WebPPicture picture;
  WebPMemoryWriter writer;
  int ok = 0;

  WebPDataInit(output);
  if (!WebPConfigInit(&config)) return 0;
  if (!WebPConfigLosslessPreset(&config, 6)) return 0;
  config.exact = 1;

  if (!ImportPicture(rgba, width, height, &picture)) return 0;

  WebPMemoryWriterInit(&writer);
  picture.writer = WebPMemoryWrite;
  picture.custom_ptr = &writer;
  ok = WebPEncode(&config, &picture);
  WebPPictureFree(&picture);
  if (!ok) {
    WebPMemoryWriterClear(&writer);
    return 0;
  }

  output->bytes = writer.mem;
  output->size = writer.size;
  return 1;
}

static int TestEncodeDecodeAndPictureUtilities(void) {
  static const int kWidth = 4;
  static const int kHeight = 3;
  uint8_t rgba[kWidth * kHeight * 4];
  WebPConfig config;
  WebPPicture source;
  WebPPicture view;
  WebPPicture derived;
  WebPData encoded;
  uint8_t* decoded = NULL;
  int width = 0, height = 0;

  FillPattern(rgba, kWidth, kHeight, 0);

  ASSERT_TRUE(WebPConfigPreset(&config, WEBP_PRESET_PHOTO, 82.f));
  ASSERT_TRUE(WebPValidateConfig(&config));
  config.segments = 0;
  ASSERT_TRUE(!WebPValidateConfig(&config));
  ASSERT_TRUE(WebPConfigInit(&config));
  ASSERT_TRUE(WebPConfigLosslessPreset(&config, 6));
  config.exact = 1;
  ASSERT_TRUE(WebPValidateConfig(&config));

  ASSERT_TRUE(ImportPicture(rgba, kWidth, kHeight, &source));
  ASSERT_TRUE(WebPPictureHasTransparency(&source));

  ASSERT_TRUE(WebPPictureView(&source, 1, 0, 3, 3, &view));
  ASSERT_TRUE(WebPPictureIsView(&view));
  ASSERT_INT_EQ(3, view.width);
  ASSERT_INT_EQ(3, view.height);

  ASSERT_TRUE(WebPPictureCopy(&view, &derived));
  ASSERT_TRUE(!WebPPictureIsView(&derived));
  ASSERT_TRUE(WebPPictureCrop(&derived, 1, 1, 2, 2));
  ASSERT_TRUE(WebPPictureRescale(&derived, 0, 4));
  ASSERT_INT_EQ(4, derived.width);
  ASSERT_INT_EQ(4, derived.height);
  ASSERT_TRUE(WebPPictureHasTransparency(&derived));
  ASSERT_TRUE(WebPPictureARGBToYUVA(&derived, WEBP_YUV420));
  ASSERT_TRUE(!derived.use_argb);
  ASSERT_TRUE(WebPPictureYUVAToARGB(&derived));
  ASSERT_TRUE(derived.use_argb);
  WebPBlendAlpha(&derived, 0x00112233u);
  ASSERT_TRUE(!WebPPictureHasTransparency(&derived));

  ASSERT_TRUE(EncodeExactLossless(rgba, kWidth, kHeight, &encoded));
  ASSERT_TRUE(WebPGetInfo(encoded.bytes, encoded.size, &width, &height));
  ASSERT_INT_EQ(kWidth, width);
  ASSERT_INT_EQ(kHeight, height);

  decoded = WebPDecodeRGBA(encoded.bytes, encoded.size, &width, &height);
  ASSERT_TRUE(decoded != NULL);
  ASSERT_INT_EQ(kWidth, width);
  ASSERT_INT_EQ(kHeight, height);
  ASSERT_MEM_EQ(rgba, decoded, sizeof(rgba));

  WebPFree(decoded);
  WebPDataClear(&encoded);
  WebPPictureFree(&derived);
  WebPPictureFree(&view);
  WebPPictureFree(&source);
  return 1;
}

static int TestAdvancedDecodeAndIncrementalDecode(void) {
  static const int kWidth = 4;
  static const int kHeight = 3;
  uint8_t rgba[kWidth * kHeight * 4];
  WebPData encoded;
  WebPDecoderConfig config;
  uint8_t external_buffer[4 * 4 * 4];
  WebPIDecoder* idec = NULL;
  uint8_t incremental_buffer[kWidth * kHeight * 4];
  uint8_t* incremental_output = NULL;
  const WebPDecBuffer* visible = NULL;
  int last_y = -1;
  int width = 0, height = 0;
  int stride = 0;
  int left = -1, top = -1, visible_width = 0, visible_height = 0;
  VP8StatusCode status;

  FillPattern(rgba, kWidth, kHeight, 0);
  ASSERT_TRUE(EncodeExactLossless(rgba, kWidth, kHeight, &encoded));

  ASSERT_TRUE(WebPInitDecoderConfig(&config));
  ASSERT_INT_EQ(VP8_STATUS_OK,
                WebPGetFeatures(encoded.bytes, encoded.size, &config.input));
  config.options.use_cropping = 1;
  config.options.crop_left = 2;
  config.options.crop_top = 0;
  config.options.crop_width = 2;
  config.options.crop_height = 2;
  config.options.use_scaling = 1;
  config.options.scaled_width = 4;
  config.options.scaled_height = 4;
  config.output.colorspace = MODE_BGRA;
  config.output.is_external_memory = 1;
  memset(external_buffer, 0xcd, sizeof(external_buffer));
  config.output.u.RGBA.rgba = external_buffer;
  config.output.u.RGBA.stride = 4 * 4;
  config.output.u.RGBA.size = sizeof(external_buffer);

  ASSERT_INT_EQ(VP8_STATUS_OK, WebPDecode(encoded.bytes, encoded.size, &config));
  ASSERT_INT_EQ(4, config.output.width);
  ASSERT_INT_EQ(4, config.output.height);
  ASSERT_TRUE(config.output.u.RGBA.rgba == external_buffer);
  ASSERT_TRUE(external_buffer[0] != 0xcd || external_buffer[1] != 0xcd ||
              external_buffer[2] != 0xcd || external_buffer[3] != 0xcd);
  WebPFreeDecBuffer(&config.output);

  idec = WebPINewRGB(MODE_RGBA, incremental_buffer, sizeof(incremental_buffer),
                     kWidth * 4);
  ASSERT_TRUE(idec != NULL);
  status = WebPIAppend(idec, encoded.bytes, 1);
  ASSERT_TRUE(status == VP8_STATUS_SUSPENDED || status == VP8_STATUS_OK);
  if (encoded.size > 1) {
    ASSERT_INT_EQ(VP8_STATUS_OK,
                  WebPIAppend(idec, encoded.bytes + 1, encoded.size - 1));
  }

  incremental_output =
      WebPIDecGetRGB(idec, &last_y, &width, &height, &stride);
  ASSERT_TRUE(incremental_output == incremental_buffer);
  ASSERT_INT_EQ(kWidth, width);
  ASSERT_INT_EQ(kHeight, height);
  ASSERT_INT_EQ(kWidth * 4, stride);
  ASSERT_INT_EQ(kHeight, last_y);
  ASSERT_MEM_EQ(rgba, incremental_output, sizeof(rgba));

  visible =
      WebPIDecodedArea(idec, &left, &top, &visible_width, &visible_height);
  ASSERT_TRUE(visible != NULL);
  ASSERT_INT_EQ(0, left);
  ASSERT_INT_EQ(0, top);
  ASSERT_INT_EQ(kWidth, visible_width);
  ASSERT_INT_EQ(kHeight, visible_height);

  WebPIDelete(idec);
  WebPDataClear(&encoded);
  return 1;
}

static int TestMuxAndDemuxRoundTrip(void) {
  static const int kWidth = 4;
  static const int kHeight = 3;
  static const uint8_t kIccp[] = {'I', 'C', 'C', 'P', 0x01, 0x02};
  static const uint8_t kExif[] = {'E', 'X', 'I', 'F', 0x10, 0x20, 0x30};
  static const uint8_t kXmp[] = {'<', 'x', 'm', 'p', '/', '>'};
  uint8_t rgba[kWidth * kHeight * 4];
  WebPData image_data;
  WebPData assembled;
  WebPData chunk_data;
  WebPData metadata;
  WebPMux* mux = NULL;
  WebPMuxFrameInfo frame;
  WebPDemuxer* demux = NULL;
  WebPChunkIterator chunk_iter;
  WebPIterator iter;
  uint32_t flags = 0;
  int canvas_width = 0, canvas_height = 0;
  int num_iccp = 0;
  uint8_t* decoded = NULL;
  int width = 0, height = 0;

  FillPattern(rgba, kWidth, kHeight, 0);
  ASSERT_TRUE(EncodeExactLossless(rgba, kWidth, kHeight, &image_data));
  WebPDataInit(&assembled);

  mux = WebPMuxNew();
  ASSERT_TRUE(mux != NULL);

  chunk_data.bytes = kIccp;
  chunk_data.size = sizeof(kIccp);
  ASSERT_INT_EQ(WEBP_MUX_OK, WebPMuxSetImage(mux, &image_data, 1));
  ASSERT_INT_EQ(WEBP_MUX_OK, WebPMuxSetChunk(mux, "ICCP", &chunk_data, 1));
  chunk_data.bytes = kExif;
  chunk_data.size = sizeof(kExif);
  ASSERT_INT_EQ(WEBP_MUX_OK, WebPMuxSetChunk(mux, "EXIF", &chunk_data, 1));
  chunk_data.bytes = kXmp;
  chunk_data.size = sizeof(kXmp);
  ASSERT_INT_EQ(WEBP_MUX_OK, WebPMuxSetChunk(mux, "XMP ", &chunk_data, 1));
  ASSERT_INT_EQ(WEBP_MUX_OK, WebPMuxAssemble(mux, &assembled));

  ASSERT_INT_EQ(WEBP_MUX_OK, WebPMuxGetFeatures(mux, &flags));
  ASSERT_TRUE((flags & ICCP_FLAG) != 0);
  ASSERT_TRUE((flags & EXIF_FLAG) != 0);
  ASSERT_TRUE((flags & XMP_FLAG) != 0);
  ASSERT_TRUE((flags & ALPHA_FLAG) != 0);
  ASSERT_INT_EQ(WEBP_MUX_OK, WebPMuxGetCanvasSize(mux, &canvas_width,
                                                  &canvas_height));
  ASSERT_INT_EQ(kWidth, canvas_width);
  ASSERT_INT_EQ(kHeight, canvas_height);
  ASSERT_INT_EQ(WEBP_MUX_OK, WebPMuxNumChunks(mux, WEBP_CHUNK_ICCP, &num_iccp));
  ASSERT_INT_EQ(1, num_iccp);

  ASSERT_INT_EQ(WEBP_MUX_OK, WebPMuxGetChunk(mux, "ICCP", &metadata));
  ASSERT_SIZE_EQ(sizeof(kIccp), metadata.size);
  ASSERT_MEM_EQ(kIccp, metadata.bytes, sizeof(kIccp));

  memset(&frame, 0, sizeof(frame));
  ASSERT_INT_EQ(WEBP_MUX_OK, WebPMuxGetFrame(mux, 1, &frame));
  ASSERT_TRUE(frame.bitstream.bytes != NULL);
  ASSERT_TRUE(WebPGetInfo(frame.bitstream.bytes, frame.bitstream.size, &width,
                          &height));
  ASSERT_INT_EQ(kWidth, width);
  ASSERT_INT_EQ(kHeight, height);
  WebPDataClear(&frame.bitstream);

  demux = WebPDemux(&assembled);
  ASSERT_TRUE(demux != NULL);
  flags = WebPDemuxGetI(demux, WEBP_FF_FORMAT_FLAGS);
  ASSERT_TRUE((flags & ICCP_FLAG) != 0);
  ASSERT_TRUE((flags & EXIF_FLAG) != 0);
  ASSERT_TRUE((flags & XMP_FLAG) != 0);
  ASSERT_TRUE((flags & ALPHA_FLAG) != 0);
  ASSERT_INT_EQ(kWidth, (int)WebPDemuxGetI(demux, WEBP_FF_CANVAS_WIDTH));
  ASSERT_INT_EQ(kHeight, (int)WebPDemuxGetI(demux, WEBP_FF_CANVAS_HEIGHT));
  ASSERT_INT_EQ(1, (int)WebPDemuxGetI(demux, WEBP_FF_FRAME_COUNT));

  ASSERT_TRUE(WebPDemuxGetChunk(demux, "EXIF", 1, &chunk_iter));
  ASSERT_SIZE_EQ(sizeof(kExif), chunk_iter.chunk.size);
  ASSERT_MEM_EQ(kExif, chunk_iter.chunk.bytes, sizeof(kExif));
  ASSERT_TRUE(!WebPDemuxNextChunk(&chunk_iter));
  WebPDemuxReleaseChunkIterator(&chunk_iter);

  ASSERT_TRUE(WebPDemuxGetFrame(demux, 1, &iter));
  ASSERT_INT_EQ(1, iter.frame_num);
  ASSERT_INT_EQ(1, iter.num_frames);
  ASSERT_INT_EQ(kWidth, iter.width);
  ASSERT_INT_EQ(kHeight, iter.height);
  ASSERT_TRUE(iter.has_alpha);
  decoded =
      WebPDecodeRGBA(iter.fragment.bytes, iter.fragment.size, &width, &height);
  ASSERT_TRUE(decoded != NULL);
  ASSERT_INT_EQ(kWidth, width);
  ASSERT_INT_EQ(kHeight, height);
  ASSERT_MEM_EQ(rgba, decoded, sizeof(rgba));
  WebPFree(decoded);
  WebPDemuxReleaseIterator(&iter);

  WebPDemuxDelete(demux);
  WebPMuxDelete(mux);
  WebPDataClear(&assembled);
  WebPDataClear(&image_data);
  return 1;
}

static int TestAnimationEncodeDecodeRoundTrip(void) {
  static const int kWidth = 2;
  static const int kHeight = 2;
  uint8_t frame0[kWidth * kHeight * 4];
  uint8_t frame1[kWidth * kHeight * 4];
  WebPAnimEncoderOptions enc_options;
  WebPAnimEncoder* enc = NULL;
  WebPConfig config;
  WebPPicture picture;
  WebPData webp_data;
  WebPAnimDecoderOptions dec_options;
  WebPAnimDecoder* dec = NULL;
  WebPAnimInfo info;
  const WebPDemuxer* demux = NULL;
  uint8_t* buffer = NULL;
  int timestamp = 0;

  FillPattern(frame0, kWidth, kHeight, 1);
  FillPattern(frame1, kWidth, kHeight, 3);

  ASSERT_TRUE(WebPAnimEncoderOptionsInit(&enc_options));
  enc_options.anim_params.loop_count = 2;
  enc_options.anim_params.bgcolor = 0x44332211u;
  enc_options.kmin = 1;
  enc_options.kmax = 1;
  enc = WebPAnimEncoderNew(kWidth, kHeight, &enc_options);
  ASSERT_TRUE(enc != NULL);

  ASSERT_TRUE(WebPConfigInit(&config));
  ASSERT_TRUE(WebPConfigLosslessPreset(&config, 6));
  config.exact = 1;

  ASSERT_TRUE(ImportPicture(frame0, kWidth, kHeight, &picture));
  ASSERT_TRUE(WebPAnimEncoderAdd(enc, &picture, 0, &config));
  WebPPictureFree(&picture);

  ASSERT_TRUE(ImportPicture(frame1, kWidth, kHeight, &picture));
  ASSERT_TRUE(WebPAnimEncoderAdd(enc, &picture, 100, &config));
  WebPPictureFree(&picture);

  ASSERT_TRUE(WebPAnimEncoderAdd(enc, NULL, 200, NULL));
  WebPDataInit(&webp_data);
  ASSERT_TRUE(WebPAnimEncoderAssemble(enc, &webp_data));
  WebPAnimEncoderDelete(enc);

  ASSERT_TRUE(WebPAnimDecoderOptionsInit(&dec_options));
  dec_options.color_mode = MODE_RGBA;
  dec = WebPAnimDecoderNew(&webp_data, &dec_options);
  ASSERT_TRUE(dec != NULL);

  ASSERT_TRUE(WebPAnimDecoderGetInfo(dec, &info));
  ASSERT_INT_EQ(kWidth, (int)info.canvas_width);
  ASSERT_INT_EQ(kHeight, (int)info.canvas_height);
  ASSERT_INT_EQ(2, (int)info.loop_count);
  ASSERT_INT_EQ(2, (int)info.frame_count);
  ASSERT_UINT32_EQ(0x44332211u, info.bgcolor);

  demux = WebPAnimDecoderGetDemuxer(dec);
  ASSERT_TRUE(demux != NULL);
  ASSERT_TRUE((WebPDemuxGetI(demux, WEBP_FF_FORMAT_FLAGS) & ANIMATION_FLAG) !=
              0);

  ASSERT_TRUE(WebPAnimDecoderHasMoreFrames(dec));
  ASSERT_TRUE(WebPAnimDecoderGetNext(dec, &buffer, &timestamp));
  ASSERT_INT_EQ(100, timestamp);
  ASSERT_MEM_EQ(frame0, buffer, sizeof(frame0));

  ASSERT_TRUE(WebPAnimDecoderHasMoreFrames(dec));
  ASSERT_TRUE(WebPAnimDecoderGetNext(dec, &buffer, &timestamp));
  ASSERT_INT_EQ(200, timestamp);
  ASSERT_MEM_EQ(frame1, buffer, sizeof(frame1));
  ASSERT_TRUE(!WebPAnimDecoderHasMoreFrames(dec));

  WebPAnimDecoderReset(dec);
  ASSERT_TRUE(WebPAnimDecoderHasMoreFrames(dec));
  ASSERT_TRUE(WebPAnimDecoderGetNext(dec, &buffer, &timestamp));
  ASSERT_INT_EQ(100, timestamp);
  ASSERT_MEM_EQ(frame0, buffer, sizeof(frame0));

  WebPAnimDecoderDelete(dec);
  WebPDataClear(&webp_data);
  return 1;
}

int main(void) {
  if (!TestEncodeDecodeAndPictureUtilities()) return EXIT_FAILURE;
  if (!TestAdvancedDecodeAndIncrementalDecode()) return EXIT_FAILURE;
  if (!TestMuxAndDemuxRoundTrip()) return EXIT_FAILURE;
  if (!TestAnimationEncodeDecodeRoundTrip()) return EXIT_FAILURE;
  return EXIT_SUCCESS;
}
