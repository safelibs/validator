
#define TEST_NAME "randombytes"
#include "cmptest.h"

static unsigned char      x[65536];
static unsigned long long freq[256];

static int
compat_tests(void)
{
    size_t i;

    memset(x, 0, sizeof x);
    randombytes(x, sizeof x);
    for (i = 0; i < 256; ++i) {
        freq[i] = 0;
    }
    for (i = 0; i < sizeof x; ++i) {
        ++freq[255 & (int) x[i]];
    }
    for (i = 0; i < 256; ++i) {
        if (!freq[i]) {
            printf("nacl_tests failed\n");
        }
    }
    return 0;
}

static int
randombytes_tests(void)
{
    static const unsigned char seed[randombytes_SEEDBYTES] = {
        0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a,
        0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15,
        0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f
    };
    static const uint32_t upper_bounds[] = {
        2U, 3U, 255U, 256U, 257U, 1024U, 65535U, 0x80000000U
    };
    unsigned char out[100];
    unsigned char out2[100];
    unsigned char seed2[randombytes_SEEDBYTES];
    unsigned int  f = 0U;
    unsigned int  i;
    size_t        j;
    uint32_t      n;

    randombytes(x, 1U);
    do {
        n = randombytes_random();
        f |= ((n >> 24) > 1);
        f |= ((n >> 16) > 1) << 1;
        f |= ((n >> 8) > 1) << 2;
        f |= ((n) > 1) << 3;
        f |= (n > 0x7fffffff) << 4;
    } while (f != 0x1f);
    randombytes_close();

    for (i = 0; i < 256; ++i) {
        freq[i] = 0;
    }
    for (i = 0; i < 65536; ++i) {
        ++freq[randombytes_uniform(256)];
    }
    for (i = 0; i < 256; ++i) {
        if (!freq[i]) {
            printf("randombytes_uniform() test failed\n");
        }
    }
    assert(randombytes_uniform(1U) == 0U);
    randombytes_close();
    randombytes_stir();
    for (i = 0; i < 256; ++i) {
        freq[i] = 0;
    }
    for (i = 0; i < 65536; ++i) {
        ++freq[randombytes_uniform(256)];
    }
    for (i = 0; i < 256; ++i) {
        if (!freq[i]) {
            printf("randombytes_uniform() test failed\n");
        }
    }
    memset(x, 0, sizeof x);
    randombytes_buf(x, sizeof x);
    for (i = 0; i < 256; ++i) {
        freq[i] = 0;
    }
    for (i = 0; i < sizeof x; ++i) {
        ++freq[255 & (int) x[i]];
    }
    for (i = 0; i < 256; ++i) {
        if (!freq[i]) {
            printf("randombytes_buf() test failed\n");
        }
    }
    assert(randombytes_uniform(1U) == 0U);

    randombytes_buf_deterministic(out, sizeof out, seed);
    for (i = 0; i < sizeof out; ++i) {
        printf("%02x", out[i]);
    }
    printf(" (deterministic)\n");
    randombytes_buf_deterministic(out2, sizeof out2, seed);
    assert(memcmp(out, out2, sizeof out) == 0);
    memcpy(seed2, seed, sizeof seed2);
    seed2[0] ^= 1U;
    randombytes_buf_deterministic(out2, sizeof out2, seed2);
    assert(memcmp(out, out2, sizeof out) != 0);

    randombytes_close();

    randombytes(x, 1U);
    randombytes_close();

    assert(randombytes_SEEDBYTES > 0);
    assert(randombytes_seedbytes() == randombytes_SEEDBYTES);
    for (j = 0U; j < sizeof upper_bounds / sizeof upper_bounds[0]; j++) {
        assert(randombytes_uniform(upper_bounds[j]) < upper_bounds[j]);
    }

    return 0;
}

int
main(void)
{
    compat_tests();
    randombytes_tests();
    printf("OK\n");

    return 0;
}
