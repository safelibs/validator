/**
 * Test public UTF-8 decoding and parser validation entry points.
 *
 * author: Daniel Veillard
 * copy: see Copyright for the status of this software.
 */

#include <stdio.h>
#include <string.h>

#include <libxml/chvalid.h>
#include <libxml/parser.h>
#include <libxml/tree.h>
#include <libxml/xmlerror.h>
#include <libxml/xmlmemory.h>
#include <libxml/xmlstring.h>

static int lastError;

static void
errorHandler(void *unused, xmlErrorPtr err) {
    if ((unused == NULL) && (err != NULL) && (lastError == 0))
        lastError = err->code;
}

static char document1[100] = "<doc>XXXX</doc>";
static char document2[100] = "<doc foo='XXXX'/>";

static void
testDocumentRangeByte1(char *document, int len, char *data, int forbid1,
                       int forbid2) {
    int i;
    xmlDocPtr res;

    for (i = 0;i <= 0xFF;i++) {
        lastError = 0;
        data[0] = (char) i;

        res = xmlReadMemory(document, len, "test", NULL, 0);

        if ((i == forbid1) || (i == forbid2)) {
            if ((lastError == 0) || (res != NULL))
                fprintf(stderr,
                        "Failed to detect invalid char for byte 0x%02X: %c\n",
                        i, i);
        } else if ((i == '<') || (i == '&')) {
            if ((lastError == 0) || (res != NULL))
                fprintf(stderr,
                        "Failed to detect illegal char %c for byte 0x%02X\n",
                        i, i);
        } else if (((i < 0x20) || (i >= 0x80)) &&
                   (i != 0x9) && (i != 0xA) && (i != 0xD)) {
            if ((lastError != XML_ERR_INVALID_CHAR) && (res != NULL))
                fprintf(stderr,
                        "Failed to detect invalid char for byte 0x%02X\n",
                        i);
        } else if (res == NULL) {
            fprintf(stderr,
                    "Failed to parse valid char for byte 0x%02X : %c\n",
                    i, i);
        }
        if (res != NULL)
            xmlFreeDoc(res);
    }
}

static void
testDocumentRangeByte2(char *document, int len, char *data) {
    int i, j;
    xmlDocPtr res;

    for (i = 0x80;i <= 0xFF;i++) {
        for (j = 0;j <= 0xFF;j++) {
            lastError = 0;
            data[0] = (char) i;
            data[1] = (char) j;

            res = xmlReadMemory(document, len, "test", NULL, 0);

            if ((i & 0x80) && ((i & 0x40) == 0)) {
                if ((lastError == 0) || (res != NULL))
                    fprintf(stderr,
                            "Failed to detect invalid char for bytes 0x%02X "
                            "0x%02X\n", i, j);
            } else if ((i & 0x80) && ((j & 0xC0) != 0x80)) {
                if ((lastError == 0) || (res != NULL))
                    fprintf(stderr,
                            "Failed to detect invalid char for bytes 0x%02X "
                            "0x%02X\n", i, j);
            } else if ((i & 0x80) && ((i & 0x1E) == 0)) {
                if ((lastError == 0) || (res != NULL))
                    fprintf(stderr,
                            "Failed to detect invalid char for bytes 0x%02X "
                            "0x%02X\n", i, j);
            } else if ((i & 0xE0) == 0xE0) {
                if ((lastError == 0) || (res != NULL))
                    fprintf(stderr,
                            "Failed to detect invalid char for bytes 0x%02X "
                            "0x%02X 0x00\n", i, j);
            } else if ((lastError != 0) || (res == NULL)) {
                fprintf(stderr,
                        "Failed to parse document for bytes 0x%02X 0x%02X\n",
                        i, j);
            }
            if (res != NULL)
                xmlFreeDoc(res);
        }
    }
}

static void
testDocumentRanges(void) {
    char *data;

    printf("testing 1 byte char in document: 1");
    fflush(stdout);
    data = &document1[5];
    memset(data, ' ', 4);
    testDocumentRangeByte1(document1, strlen(document1), data, -1, -1);

    printf(" 2");
    fflush(stdout);
    memset(data, ' ', 4);
    testDocumentRangeByte1(document1, strlen(document1), data + 3, -1, -1);

    printf(" 3");
    fflush(stdout);
    data = &document2[10];
    memset(data, ' ', 4);
    testDocumentRangeByte1(document2, strlen(document2), data, '\'', -1);

    printf(" 4");
    fflush(stdout);
    memset(data, ' ', 4);
    testDocumentRangeByte1(document2, strlen(document2), data + 3, '\'', -1);
    printf(" done\n");

    printf("testing 2 byte char in document: 1");
    fflush(stdout);
    data = &document1[5];
    memset(data, ' ', 4);
    testDocumentRangeByte2(document1, strlen(document1), data);

    printf(" 2");
    fflush(stdout);
    memset(data, ' ', 4);
    testDocumentRangeByte2(document1, strlen(document1), data + 2);

    printf(" 3");
    fflush(stdout);
    data = &document2[10];
    memset(data, ' ', 4);
    testDocumentRangeByte2(document2, strlen(document2), data);

    printf(" 4");
    fflush(stdout);
    memset(data, ' ', 4);
    testDocumentRangeByte2(document2, strlen(document2), data + 2);
    printf(" done\n");
}

/*
 * xmlGetUTF8Char is the closest public decoder entry point. It validates
 * UTF-8 structure, while parser-only behaviors like newline normalization
 * remain covered by the document-level tests above.
 */
static void
testUtf8RangeByte1(char *data) {
    int i;

    data[1] = 0;
    for (i = 0;i <= 0xFF;i++) {
        int len = 1;
        int c;

        data[0] = (char) i;
        c = xmlGetUTF8Char((const unsigned char *) data, &len);

        if (i >= 0x80) {
            if ((c != -1) || (len != 0))
                fprintf(stderr,
                        "Failed to reject single byte 0x%02X\n", i);
        } else if ((c != i) || (len != 1)) {
            fprintf(stderr,
                    "Failed to decode single byte 0x%02X\n", i);
        }
    }
}

static void
testUtf8RangeByte2(char *data) {
    int i, j;

    data[2] = 0;
    for (i = 0x80;i <= 0xFF;i++) {
        for (j = 0;j <= 0xFF;j++) {
            int len = 2;
            int c;

            data[0] = (char) i;
            data[1] = (char) j;
            c = xmlGetUTF8Char((const unsigned char *) data, &len);

            if ((i >= 0xE0) || ((j & 0xC0) != 0x80)) {
                if ((c != -1) || (len != 0))
                    fprintf(stderr,
                            "Failed to reject bytes 0x%02X 0x%02X\n", i, j);
            } else if ((len != 2) ||
                       (c != ((j & 0x3F) + ((i & 0x1F) << 6)))) {
                fprintf(stderr,
                        "Failed to decode bytes 0x%02X 0x%02X\n", i, j);
            }
        }
    }
}

static void
testUtf8RangeByte3(char *data) {
    int i, j, k;

    data[3] = 0;
    for (i = 0xE0;i <= 0xFF;i++) {
        for (j = 0;j <= 0xFF;j++) {
            for (k = 0;k <= 0xFF;k++) {
                int len = 3;
                int c;

                data[0] = (char) i;
                data[1] = (char) j;
                data[2] = (char) k;
                c = xmlGetUTF8Char((const unsigned char *) data, &len);

                if (((i & 0xF0) != 0xE0) ||
                    ((j & 0xC0) != 0x80) ||
                    ((k & 0xC0) != 0x80)) {
                    if ((c != -1) || (len != 0))
                        fprintf(stderr,
                                "Failed to reject bytes 0x%02X 0x%02X "
                                "0x%02X\n", i, j, k);
                } else if ((len != 3) ||
                           (c != ((k & 0x3F) + ((j & 0x3F) << 6) +
                                  ((i & 0x0F) << 12)))) {
                    fprintf(stderr,
                            "Failed to decode bytes 0x%02X 0x%02X 0x%02X\n",
                            i, j, k);
                }
            }
        }
    }
}

static void
testUtf8RangeByte4(char *data) {
    int i, j, k, l;
    unsigned char tails[] = { 0x00, 0x7F, 0x80, 0xBF, 0xC0, 0xFF };

    data[4] = 0;
    for (i = 0xF0;i <= 0xFF;i++) {
        for (j = 0;j <= 0xFF;j++) {
            for (k = 0;k < (int) (sizeof(tails) / sizeof(tails[0]));k++) {
                for (l = 0;l < (int) (sizeof(tails) / sizeof(tails[0]));l++) {
                    int len = 4;
                    int c;
                    int third = tails[k];
                    int fourth = tails[l];

                    data[0] = (char) i;
                    data[1] = (char) j;
                    data[2] = (char) third;
                    data[3] = (char) fourth;
                    c = xmlGetUTF8Char((const unsigned char *) data, &len);

                    if (((i & 0xF8) != 0xF0) ||
                        ((j & 0xC0) != 0x80) ||
                        ((third & 0xC0) != 0x80) ||
                        ((fourth & 0xC0) != 0x80)) {
                        if ((c != -1) || (len != 0))
                            fprintf(stderr,
                                    "Failed to reject bytes 0x%02X 0x%02X "
                                    "0x%02X 0x%02X\n",
                                    i, j, third, fourth);
                    } else if ((len != 4) ||
                               (c != ((fourth & 0x3F) +
                                      ((third & 0x3F) << 6) +
                                      ((j & 0x3F) << 12) +
                                      ((i & 0x07) << 18)))) {
                        fprintf(stderr,
                                "Failed to decode bytes 0x%02X 0x%02X "
                                "0x%02X 0x%02X\n",
                                i, j, third, fourth);
                    }
                }
            }
        }
    }
}

static void
testUtf8DecoderRanges(void) {
    char data[5];

    memset(data, 0, sizeof(data));

    printf("testing UTF-8 decoder: 1");
    fflush(stdout);
    testUtf8RangeByte1(data);

    printf(" 2");
    fflush(stdout);
    testUtf8RangeByte2(data);

    printf(" 3");
    fflush(stdout);
    testUtf8RangeByte3(data);

    printf(" 4");
    fflush(stdout);
    testUtf8RangeByte4(data);
    printf(" done\n");
}

typedef struct {
    const char *name;
    unsigned char bytes[4];
    int len;
    int should_parse;
} utf8DocumentCase;

static const utf8DocumentCase documentCases[] = {
    { "valid-3-byte-min", { 0xE0, 0xA0, 0x80, 0x00 }, 3, 1 },
    { "valid-3-byte-max-bmp", { 0xED, 0x9F, 0xBF, 0x00 }, 3, 1 },
    { "valid-3-byte-post-surrogate", { 0xEE, 0x80, 0x80, 0x00 }, 3, 1 },
    { "valid-4-byte-min", { 0xF0, 0x90, 0x80, 0x80 }, 4, 1 },
    { "valid-4-byte-max", { 0xF4, 0x8F, 0xBF, 0xBF }, 4, 1 },
    { "invalid-3-byte-overlong", { 0xE0, 0x80, 0x80, 0x00 }, 3, 0 },
    { "invalid-3-byte-surrogate", { 0xED, 0xA0, 0x80, 0x00 }, 3, 0 },
    { "invalid-3-byte-short", { 0xE0, 0xA0, 0x00, 0x00 }, 3, 0 },
    { "invalid-4-byte-overlong", { 0xF0, 0x80, 0x80, 0x80 }, 4, 0 },
    { "invalid-4-byte-out-of-range", { 0xF4, 0x90, 0x80, 0x80 }, 4, 0 },
    { "invalid-4-byte-short", { 0xF0, 0x90, 0x80, 0x00 }, 4, 0 },
};

static void
testDocumentUtf8Samples(void) {
    char document[64];
    size_t prefix_len;
    size_t suffix_len;
    int i;

    memcpy(document, "<doc>", 5);
    prefix_len = 5;
    suffix_len = 6;

    printf("testing 3/4 byte document samples");
    fflush(stdout);
    for (i = 0;i < (int) (sizeof(documentCases) / sizeof(documentCases[0]));i++) {
        xmlDocPtr res;
        size_t doc_len;

        memcpy(document + prefix_len, documentCases[i].bytes,
               documentCases[i].len);
        memcpy(document + prefix_len + documentCases[i].len, "</doc>", 6);
        doc_len = prefix_len + documentCases[i].len + suffix_len;
        document[doc_len] = 0;

        lastError = 0;
        res = xmlReadMemory(document, doc_len, documentCases[i].name,
                            NULL, 0);
        if (documentCases[i].should_parse) {
            if ((res == NULL) || (lastError != 0))
                fprintf(stderr, "Failed to parse sample %s\n",
                        documentCases[i].name);
        } else if ((res != NULL) || (lastError != XML_ERR_INVALID_CHAR)) {
            fprintf(stderr, "Failed to reject sample %s\n",
                    documentCases[i].name);
        }
        if (res != NULL)
            xmlFreeDoc(res);
    }
    printf(" done\n");
}

int
main(void) {
    LIBXML_TEST_VERSION

    xmlSetStructuredErrorFunc(NULL, errorHandler);

    testUtf8DecoderRanges();
    testDocumentRanges();
    testDocumentUtf8Samples();

    xmlCleanupParser();
    xmlMemoryDump();
    return(0);
}
