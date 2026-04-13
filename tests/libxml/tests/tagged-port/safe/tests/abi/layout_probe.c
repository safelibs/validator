#include <stddef.h>
#include <stdio.h>

#include <libxml/entities.h>
#include <libxml/parser.h>
#include <libxml/tree.h>
#include <libxml/xmlIO.h>
#include <libxml/xmlerror.h>
#include <libxml/xpath.h>

#define PRINT_FIELD(type, field, trailer) \
    printf("      \"" #field "\": %zu" trailer "\n", offsetof(type, field))

int
main(void) {
    printf("{\n");
    printf("  \"sizeof\": {\n");
    printf("    \"xmlAttribute\": %zu,\n", sizeof(xmlAttribute));
    printf("    \"xmlAttr\": %zu,\n", sizeof(xmlAttr));
    printf("    \"xmlBuffer\": %zu,\n", sizeof(xmlBuffer));
    printf("    \"xmlDoc\": %zu,\n", sizeof(xmlDoc));
    printf("    \"xmlDtd\": %zu,\n", sizeof(xmlDtd));
    printf("    \"xmlEntity\": %zu,\n", sizeof(xmlEntity));
    printf("    \"xmlError\": %zu,\n", sizeof(xmlError));
    printf("    \"xmlNode\": %zu,\n", sizeof(xmlNode));
    printf("    \"xmlOutputBuffer\": %zu,\n", sizeof(xmlOutputBuffer));
    printf("    \"xmlParserCtxt\": %zu,\n", sizeof(xmlParserCtxt));
    printf("    \"xmlParserInputBuffer\": %zu,\n", sizeof(xmlParserInputBuffer));
    printf("    \"xmlXPathContext\": %zu,\n", sizeof(xmlXPathContext));
    printf("    \"xmlXPathObject\": %zu\n", sizeof(xmlXPathObject));
    printf("  },\n");
    printf("  \"offsetof\": {\n");

    printf("    \"xmlNode\": {\n");
    PRINT_FIELD(xmlNode, type, ",");
    PRINT_FIELD(xmlNode, name, ",");
    PRINT_FIELD(xmlNode, children, ",");
    PRINT_FIELD(xmlNode, last, ",");
    PRINT_FIELD(xmlNode, parent, ",");
    PRINT_FIELD(xmlNode, next, ",");
    PRINT_FIELD(xmlNode, prev, ",");
    PRINT_FIELD(xmlNode, doc, ",");
    PRINT_FIELD(xmlNode, ns, ",");
    PRINT_FIELD(xmlNode, content, ",");
    PRINT_FIELD(xmlNode, properties, ",");
    PRINT_FIELD(xmlNode, nsDef, ",");
    PRINT_FIELD(xmlNode, line, "");
    printf("    },\n");

    printf("    \"xmlDoc\": {\n");
    PRINT_FIELD(xmlDoc, type, ",");
    PRINT_FIELD(xmlDoc, children, ",");
    PRINT_FIELD(xmlDoc, last, ",");
    PRINT_FIELD(xmlDoc, parent, ",");
    PRINT_FIELD(xmlDoc, next, ",");
    PRINT_FIELD(xmlDoc, prev, ",");
    PRINT_FIELD(xmlDoc, doc, ",");
    PRINT_FIELD(xmlDoc, compression, ",");
    PRINT_FIELD(xmlDoc, standalone, ",");
    PRINT_FIELD(xmlDoc, intSubset, ",");
    PRINT_FIELD(xmlDoc, extSubset, ",");
    PRINT_FIELD(xmlDoc, oldNs, ",");
    PRINT_FIELD(xmlDoc, version, ",");
    PRINT_FIELD(xmlDoc, encoding, ",");
    PRINT_FIELD(xmlDoc, URL, "");
    printf("    },\n");

    printf("    \"xmlAttr\": {\n");
    PRINT_FIELD(xmlAttr, type, ",");
    PRINT_FIELD(xmlAttr, name, ",");
    PRINT_FIELD(xmlAttr, children, ",");
    PRINT_FIELD(xmlAttr, last, ",");
    PRINT_FIELD(xmlAttr, parent, ",");
    PRINT_FIELD(xmlAttr, next, ",");
    PRINT_FIELD(xmlAttr, prev, ",");
    PRINT_FIELD(xmlAttr, doc, ",");
    PRINT_FIELD(xmlAttr, ns, ",");
    PRINT_FIELD(xmlAttr, atype, "");
    printf("    },\n");

    printf("    \"xmlDtd\": {\n");
    PRINT_FIELD(xmlDtd, type, ",");
    PRINT_FIELD(xmlDtd, name, ",");
    PRINT_FIELD(xmlDtd, children, ",");
    PRINT_FIELD(xmlDtd, last, ",");
    PRINT_FIELD(xmlDtd, parent, ",");
    PRINT_FIELD(xmlDtd, next, ",");
    PRINT_FIELD(xmlDtd, prev, ",");
    PRINT_FIELD(xmlDtd, doc, ",");
    PRINT_FIELD(xmlDtd, ExternalID, ",");
    PRINT_FIELD(xmlDtd, SystemID, ",");
    PRINT_FIELD(xmlDtd, entities, ",");
    PRINT_FIELD(xmlDtd, elements, ",");
    PRINT_FIELD(xmlDtd, attributes, ",");
    PRINT_FIELD(xmlDtd, notations, "");
    printf("    },\n");

    printf("    \"xmlEntity\": {\n");
    PRINT_FIELD(xmlEntity, type, ",");
    PRINT_FIELD(xmlEntity, name, ",");
    PRINT_FIELD(xmlEntity, children, ",");
    PRINT_FIELD(xmlEntity, last, ",");
    PRINT_FIELD(xmlEntity, parent, ",");
    PRINT_FIELD(xmlEntity, next, ",");
    PRINT_FIELD(xmlEntity, prev, ",");
    PRINT_FIELD(xmlEntity, doc, ",");
    PRINT_FIELD(xmlEntity, orig, ",");
    PRINT_FIELD(xmlEntity, content, ",");
    PRINT_FIELD(xmlEntity, length, ",");
    PRINT_FIELD(xmlEntity, etype, "");
    printf("    },\n");

    printf("    \"xmlError\": {\n");
    PRINT_FIELD(xmlError, domain, ",");
    PRINT_FIELD(xmlError, code, ",");
    PRINT_FIELD(xmlError, message, ",");
    PRINT_FIELD(xmlError, level, ",");
    PRINT_FIELD(xmlError, file, ",");
    PRINT_FIELD(xmlError, line, ",");
    PRINT_FIELD(xmlError, str1, ",");
    PRINT_FIELD(xmlError, str2, ",");
    PRINT_FIELD(xmlError, str3, ",");
    PRINT_FIELD(xmlError, int1, ",");
    PRINT_FIELD(xmlError, int2, ",");
    PRINT_FIELD(xmlError, ctxt, ",");
    PRINT_FIELD(xmlError, node, "");
    printf("    },\n");

    printf("    \"xmlBuffer\": {\n");
    PRINT_FIELD(xmlBuffer, content, ",");
    PRINT_FIELD(xmlBuffer, use, ",");
    PRINT_FIELD(xmlBuffer, size, ",");
    PRINT_FIELD(xmlBuffer, alloc, ",");
    PRINT_FIELD(xmlBuffer, contentIO, "");
    printf("    },\n");

    printf("    \"xmlParserInputBuffer\": {\n");
    PRINT_FIELD(xmlParserInputBuffer, context, ",");
    PRINT_FIELD(xmlParserInputBuffer, readcallback, ",");
    PRINT_FIELD(xmlParserInputBuffer, closecallback, ",");
    PRINT_FIELD(xmlParserInputBuffer, encoder, ",");
    PRINT_FIELD(xmlParserInputBuffer, buffer, ",");
    PRINT_FIELD(xmlParserInputBuffer, raw, ",");
    PRINT_FIELD(xmlParserInputBuffer, compressed, ",");
    PRINT_FIELD(xmlParserInputBuffer, error, ",");
    PRINT_FIELD(xmlParserInputBuffer, rawconsumed, "");
    printf("    },\n");

    printf("    \"xmlOutputBuffer\": {\n");
    PRINT_FIELD(xmlOutputBuffer, context, ",");
    PRINT_FIELD(xmlOutputBuffer, writecallback, ",");
    PRINT_FIELD(xmlOutputBuffer, closecallback, ",");
    PRINT_FIELD(xmlOutputBuffer, encoder, ",");
    PRINT_FIELD(xmlOutputBuffer, buffer, ",");
    PRINT_FIELD(xmlOutputBuffer, conv, ",");
    PRINT_FIELD(xmlOutputBuffer, written, ",");
    PRINT_FIELD(xmlOutputBuffer, error, "");
    printf("    },\n");

    printf("    \"xmlParserCtxt\": {\n");
    PRINT_FIELD(xmlParserCtxt, sax, ",");
    PRINT_FIELD(xmlParserCtxt, userData, ",");
    PRINT_FIELD(xmlParserCtxt, myDoc, ",");
    PRINT_FIELD(xmlParserCtxt, wellFormed, ",");
    PRINT_FIELD(xmlParserCtxt, replaceEntities, ",");
    PRINT_FIELD(xmlParserCtxt, version, ",");
    PRINT_FIELD(xmlParserCtxt, encoding, ",");
    PRINT_FIELD(xmlParserCtxt, standalone, ",");
    PRINT_FIELD(xmlParserCtxt, html, ",");
    PRINT_FIELD(xmlParserCtxt, inputNr, ",");
    PRINT_FIELD(xmlParserCtxt, input, ",");
    PRINT_FIELD(xmlParserCtxt, node, ",");
    PRINT_FIELD(xmlParserCtxt, dict, ",");
    PRINT_FIELD(xmlParserCtxt, options, "");
    printf("    },\n");

    printf("    \"xmlXPathObject\": {\n");
    PRINT_FIELD(xmlXPathObject, type, ",");
    PRINT_FIELD(xmlXPathObject, nodesetval, ",");
    PRINT_FIELD(xmlXPathObject, boolval, ",");
    PRINT_FIELD(xmlXPathObject, floatval, ",");
    PRINT_FIELD(xmlXPathObject, stringval, ",");
    PRINT_FIELD(xmlXPathObject, user, ",");
    PRINT_FIELD(xmlXPathObject, index, ",");
    PRINT_FIELD(xmlXPathObject, user2, ",");
    PRINT_FIELD(xmlXPathObject, index2, "");
    printf("    },\n");

    printf("    \"xmlXPathContext\": {\n");
    PRINT_FIELD(xmlXPathContext, doc, ",");
    PRINT_FIELD(xmlXPathContext, node, ",");
    PRINT_FIELD(xmlXPathContext, varHash, ",");
    PRINT_FIELD(xmlXPathContext, nsHash, ",");
    PRINT_FIELD(xmlXPathContext, nb_types, ",");
    PRINT_FIELD(xmlXPathContext, types, ",");
    PRINT_FIELD(xmlXPathContext, funcHash, ",");
    PRINT_FIELD(xmlXPathContext, axis, ",");
    PRINT_FIELD(xmlXPathContext, namespaces, ",");
    PRINT_FIELD(xmlXPathContext, nsNr, ",");
    PRINT_FIELD(xmlXPathContext, user, ",");
    PRINT_FIELD(xmlXPathContext, contextSize, ",");
    PRINT_FIELD(xmlXPathContext, proximityPosition, ",");
    PRINT_FIELD(xmlXPathContext, extra, "");
    printf("    }\n");

    printf("  }\n");
    printf("}\n");
    return 0;
}
