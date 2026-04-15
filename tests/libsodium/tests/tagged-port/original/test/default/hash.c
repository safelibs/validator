
#define TEST_NAME "hash"
#include "cmptest.h"

static unsigned char x[] = "testing\n";
static unsigned char x2[] =
    "The Conscience of a Hacker is a small essay written January 8, 1986 by a "
    "computer security hacker who went by the handle of The Mentor, who "
    "belonged to the 2nd generation of Legion of Doom.";
static unsigned char empty[1];
static unsigned char h[crypto_hash_BYTES];

static void
assert_sha256_incremental(const unsigned char *m, size_t mlen)
{
    crypto_hash_sha256_state st;
    unsigned char            expected[crypto_hash_sha256_BYTES];
    unsigned char            actual[crypto_hash_sha256_BYTES];
    size_t                   l1 = mlen / 3U;
    size_t                   l2 = mlen / 2U;

    assert(crypto_hash_sha256(expected, m, (unsigned long long) mlen) == 0);
    assert(crypto_hash_sha256_init(&st) == 0);
    assert(crypto_hash_sha256_update(&st, m, 0U) == 0);
    assert(crypto_hash_sha256_update(&st, m, (unsigned long long) l1) == 0);
    assert(crypto_hash_sha256_update(&st, m + l1,
                                     (unsigned long long) (l2 - l1)) == 0);
    assert(crypto_hash_sha256_update(&st, m + l2,
                                     (unsigned long long) (mlen - l2)) == 0);
    assert(crypto_hash_sha256_update(&st, m, 0U) == 0);
    assert(crypto_hash_sha256_final(&st, actual) == 0);
    assert(memcmp(expected, actual, sizeof expected) == 0);
}

static void
assert_sha512_incremental(const unsigned char *m, size_t mlen)
{
    crypto_hash_sha512_state st;
    unsigned char            generic[crypto_hash_BYTES];
    unsigned char            expected[crypto_hash_sha512_BYTES];
    unsigned char            actual[crypto_hash_sha512_BYTES];
    size_t                   l1 = mlen / 3U;
    size_t                   l2 = mlen / 2U;

    assert(crypto_hash_sha512(expected, m, (unsigned long long) mlen) == 0);
    assert(crypto_hash(generic, m, (unsigned long long) mlen) == 0);
    assert(memcmp(generic, expected, sizeof expected) == 0);
    assert(crypto_hash_sha512_init(&st) == 0);
    assert(crypto_hash_sha512_update(&st, m, 0U) == 0);
    assert(crypto_hash_sha512_update(&st, m, (unsigned long long) l1) == 0);
    assert(crypto_hash_sha512_update(&st, m + l1,
                                     (unsigned long long) (l2 - l1)) == 0);
    assert(crypto_hash_sha512_update(&st, m + l2,
                                     (unsigned long long) (mlen - l2)) == 0);
    assert(crypto_hash_sha512_update(&st, m, 0U) == 0);
    assert(crypto_hash_sha512_final(&st, actual) == 0);
    assert(memcmp(expected, actual, sizeof expected) == 0);
}

int
main(void)
{
    size_t i;

    crypto_hash(h, x, sizeof x - 1U);
    for (i = 0; i < crypto_hash_BYTES; ++i) {
        printf("%02x", (unsigned int) h[i]);
    }
    printf("\n");
    crypto_hash(h, x2, sizeof x2 - 1U);
    for (i = 0; i < crypto_hash_BYTES; ++i) {
        printf("%02x", (unsigned int) h[i]);
    }
    printf("\n");
    crypto_hash_sha256(h, x, sizeof x - 1U);
    for (i = 0; i < crypto_hash_sha256_BYTES; ++i) {
        printf("%02x", (unsigned int) h[i]);
    }
    printf("\n");
    crypto_hash_sha256(h, x2, sizeof x2 - 1U);
    for (i = 0; i < crypto_hash_sha256_BYTES; ++i) {
        printf("%02x", (unsigned int) h[i]);
    }
    printf("\n");

    assert_sha256_incremental(empty, 0U);
    assert_sha256_incremental(x, sizeof x - 1U);
    assert_sha256_incremental(x2, sizeof x2 - 1U);
    assert_sha512_incremental(empty, 0U);
    assert_sha512_incremental(x, sizeof x - 1U);
    assert_sha512_incremental(x2, sizeof x2 - 1U);

    assert(crypto_hash_bytes() > 0U);
    assert(strcmp(crypto_hash_primitive(), "sha512") == 0);
    assert(crypto_hash_sha256_bytes() > 0U);
    assert(crypto_hash_sha512_bytes() >= crypto_hash_sha256_bytes());
    assert(crypto_hash_sha512_bytes() == crypto_hash_bytes());
    assert(crypto_hash_sha256_statebytes() == sizeof(crypto_hash_sha256_state));
    assert(crypto_hash_sha512_statebytes() == sizeof(crypto_hash_sha512_state));

    return 0;
}
