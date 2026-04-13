/*
 * testXPath.c : a small tester program for XPath.
 *
 * See Copyright for the status of this software.
 *
 * daniel@veillard.com
 */

#include "libxml.h"
#if defined(LIBXML_XPATH_ENABLED) && defined(LIBXML_DEBUG_ENABLED)

#include <string.h>

#ifdef HAVE_SYS_TYPES_H
#include <sys/types.h>
#endif
#ifdef HAVE_SYS_STAT_H
#include <sys/stat.h>
#endif
#ifdef HAVE_FCNTL_H
#include <fcntl.h>
#endif
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif


#include <libxml/xpath.h>
#include <libxml/tree.h>
#include <libxml/parser.h>
#include <libxml/debugXML.h>
#include <libxml/xmlmemory.h>
#include <libxml/xmlerror.h>
#include <libxml/globals.h>
#if defined(LIBXML_XPTR_ENABLED)
#include <libxml/xpointer.h>
static int xptr = 0;
#endif
static int debug = 0;
static int valid = 0;
static int expr = 0;
static int tree = 0;
static int nocdata = 0;
static xmlDocPtr document = NULL;

/*
 * Default document
 */
static xmlChar buffer[] =
"<?xml version=\"1.0\"?>\n\
<EXAMPLE prop1=\"gnome is great\" prop2=\"&amp; linux too\">\n\
  <head>\n\
   <title>Welcome to Gnome</title>\n\
  </head>\n\
  <chapter>\n\
   <title>The Linux adventure</title>\n\
   <p>bla bla bla ...</p>\n\
   <image href=\"linus.gif\"/>\n\
   <p>...</p>\n\
  </chapter>\n\
  <chapter>\n\
   <title>Chapter 2</title>\n\
   <p>this is chapter 2 ...</p>\n\
  </chapter>\n\
  <chapter>\n\
   <title>Chapter 3</title>\n\
   <p>this is chapter 3 ...</p>\n\
  </chapter>\n\
</EXAMPLE>\n\
";

static void testXPathDebugDumpObject(FILE *output, xmlXPathObjectPtr cur,
                                     int depth);

static void
testXPathDebugDumpNode(FILE *output, xmlNodePtr cur, int depth) {
    int i;
    char shift[100];

    for (i = 0;((i < depth) && (i < 25));i++)
        shift[2 * i] = shift[2 * i + 1] = ' ';
    shift[2 * i] = shift[2 * i + 1] = 0;
    if (cur == NULL) {
        fprintf(output, "%s", shift);
        fprintf(output, "Node is NULL !\n");
        return;
    }

    if ((cur->type == XML_DOCUMENT_NODE) ||
        (cur->type == XML_HTML_DOCUMENT_NODE)) {
        fprintf(output, "%s", shift);
        fprintf(output, " /\n");
    } else if (cur->type == XML_ATTRIBUTE_NODE) {
        xmlDebugDumpAttr(output, (xmlAttrPtr) cur, depth);
    } else {
        xmlDebugDumpOneNode(output, cur, depth);
    }
}

static void
testXPathDebugDumpNodeList(FILE *output, xmlNodePtr cur, int depth) {
    xmlNodePtr tmp;
    int i;
    char shift[100];

    for (i = 0;((i < depth) && (i < 25));i++)
        shift[2 * i] = shift[2 * i + 1] = ' ';
    shift[2 * i] = shift[2 * i + 1] = 0;
    if (cur == NULL) {
        fprintf(output, "%s", shift);
        fprintf(output, "Node is NULL !\n");
        return;
    }

    while (cur != NULL) {
        tmp = cur;
        cur = cur->next;
        xmlDebugDumpOneNode(output, tmp, depth);
    }
}

static void
testXPathDebugDumpNodeSet(FILE *output, xmlNodeSetPtr cur, int depth) {
    int i;
    char shift[100];

    for (i = 0;((i < depth) && (i < 25));i++)
        shift[2 * i] = shift[2 * i + 1] = ' ';
    shift[2 * i] = shift[2 * i + 1] = 0;

    if (cur == NULL) {
        fprintf(output, "%s", shift);
        fprintf(output, "NodeSet is NULL !\n");
        return;
    }

    fprintf(output, "Set contains %d nodes:\n", cur->nodeNr);
    for (i = 0;i < cur->nodeNr;i++) {
        fprintf(output, "%s", shift);
        fprintf(output, "%d", i + 1);
        testXPathDebugDumpNode(output, cur->nodeTab[i], depth + 1);
    }
}

static void
testXPathDebugDumpValueTree(FILE *output, xmlNodeSetPtr cur, int depth) {
    int i;
    char shift[100];

    for (i = 0;((i < depth) && (i < 25));i++)
        shift[2 * i] = shift[2 * i + 1] = ' ';
    shift[2 * i] = shift[2 * i + 1] = 0;

    if ((cur == NULL) || (cur->nodeNr == 0) || (cur->nodeTab[0] == NULL)) {
        fprintf(output, "%s", shift);
        fprintf(output, "Value Tree is NULL !\n");
        return;
    }

    fprintf(output, "%s", shift);
    fprintf(output, "%d", i + 1);
    testXPathDebugDumpNodeList(output, cur->nodeTab[0]->children, depth + 1);
}

#if defined(LIBXML_XPTR_ENABLED)
static void
testXPathDebugDumpLocationSet(FILE *output, xmlLocationSetPtr cur, int depth) {
    int i;
    char shift[100];

    for (i = 0;((i < depth) && (i < 25));i++)
        shift[2 * i] = shift[2 * i + 1] = ' ';
    shift[2 * i] = shift[2 * i + 1] = 0;

    if (cur == NULL) {
        fprintf(output, "%s", shift);
        fprintf(output, "LocationSet is NULL !\n");
        return;
    }

    for (i = 0;i < cur->locNr;i++) {
        fprintf(output, "%s", shift);
        fprintf(output, "%d : ", i + 1);
        testXPathDebugDumpObject(output, cur->locTab[i], depth + 1);
    }
}
#endif

static void
testXPathDebugDumpObject(FILE *output, xmlXPathObjectPtr cur, int depth) {
    int i;
    char shift[100];

    if (output == NULL)
        return;

    for (i = 0;((i < depth) && (i < 25));i++)
        shift[2 * i] = shift[2 * i + 1] = ' ';
    shift[2 * i] = shift[2 * i + 1] = 0;

    fprintf(output, "%s", shift);

    if (cur == NULL) {
        fprintf(output, "Object is empty (NULL)\n");
        return;
    }
    switch (cur->type) {
        case XPATH_UNDEFINED:
            fprintf(output, "Object is uninitialized\n");
            break;
        case XPATH_NODESET:
            fprintf(output, "Object is a Node Set :\n");
            testXPathDebugDumpNodeSet(output, cur->nodesetval, depth);
            break;
        case XPATH_XSLT_TREE:
            fprintf(output, "Object is an XSLT value tree :\n");
            testXPathDebugDumpValueTree(output, cur->nodesetval, depth);
            break;
        case XPATH_BOOLEAN:
            fprintf(output, "Object is a Boolean : ");
            if (cur->boolval)
                fprintf(output, "true\n");
            else
                fprintf(output, "false\n");
            break;
        case XPATH_NUMBER:
            switch (xmlXPathIsInf(cur->floatval)) {
                case 1:
                    fprintf(output, "Object is a number : Infinity\n");
                    break;
                case -1:
                    fprintf(output, "Object is a number : -Infinity\n");
                    break;
                default:
                    if (xmlXPathIsNaN(cur->floatval)) {
                        fprintf(output, "Object is a number : NaN\n");
                    } else if (cur->floatval == 0) {
                        fprintf(output, "Object is a number : 0\n");
                    } else {
                        fprintf(output, "Object is a number : %0g\n",
                                cur->floatval);
                    }
            }
            break;
        case XPATH_STRING:
            fprintf(output, "Object is a string : ");
            xmlDebugDumpString(output, cur->stringval);
            fprintf(output, "\n");
            break;
        case XPATH_POINT:
            fprintf(output, "Object is a point : index %d in node",
                    cur->index);
            testXPathDebugDumpNode(output, (xmlNodePtr) cur->user, depth + 1);
            fprintf(output, "\n");
            break;
        case XPATH_RANGE:
            if ((cur->user2 == NULL) ||
                ((cur->user2 == cur->user) &&
                 (cur->index == cur->index2))) {
                fprintf(output, "Object is a collapsed range :\n");
                fprintf(output, "%s", shift);
                if (cur->index >= 0)
                    fprintf(output, "index %d in ", cur->index);
                fprintf(output, "node\n");
                testXPathDebugDumpNode(output, (xmlNodePtr) cur->user,
                                       depth + 1);
            } else {
                fprintf(output, "Object is a range :\n");
                fprintf(output, "%s", shift);
                fprintf(output, "From ");
                if (cur->index >= 0)
                    fprintf(output, "index %d in ", cur->index);
                fprintf(output, "node\n");
                testXPathDebugDumpNode(output, (xmlNodePtr) cur->user,
                                       depth + 1);
                fprintf(output, "%s", shift);
                fprintf(output, "To ");
                if (cur->index2 >= 0)
                    fprintf(output, "index %d in ", cur->index2);
                fprintf(output, "node\n");
                testXPathDebugDumpNode(output, (xmlNodePtr) cur->user2,
                                       depth + 1);
                fprintf(output, "\n");
            }
            break;
        case XPATH_LOCATIONSET:
#if defined(LIBXML_XPTR_ENABLED)
            fprintf(output, "Object is a Location Set:\n");
            testXPathDebugDumpLocationSet(output,
                                          (xmlLocationSetPtr) cur->user,
                                          depth);
#endif
            break;
        case XPATH_USERS:
            fprintf(output, "Object is user defined\n");
            break;
    }
}


static void
testXPath(const char *str) {
    xmlXPathObjectPtr res;
    xmlXPathContextPtr ctxt;

#if defined(LIBXML_XPTR_ENABLED)
    if (xptr) {
	ctxt = xmlXPtrNewContext(document, NULL, NULL);
	res = xmlXPtrEval(BAD_CAST str, ctxt);
    } else {
#endif
	ctxt = xmlXPathNewContext(document);
	ctxt->node = xmlDocGetRootElement(document);
	if (expr)
	    res = xmlXPathEvalExpression(BAD_CAST str, ctxt);
	else {
	    /* res = xmlXPathEval(BAD_CAST str, ctxt); */
	    xmlXPathCompExprPtr comp;

	    comp = xmlXPathCompile(BAD_CAST str);
	    if (comp != NULL) {
		res = xmlXPathCompiledEval(comp, ctxt);
		xmlXPathFreeCompExpr(comp);
	    } else
		res = NULL;
	}
#if defined(LIBXML_XPTR_ENABLED)
    }
#endif
    testXPathDebugDumpObject(stdout, res, 0);
    xmlXPathFreeObject(res);
    xmlXPathFreeContext(ctxt);
}

static void
testXPathFile(const char *filename) {
    FILE *input;
    char expression[5000];
    int len;

    input = fopen(filename, "r");
    if (input == NULL) {
        xmlGenericError(xmlGenericErrorContext,
		"Cannot open %s for reading\n", filename);
	return;
    }
    while (fgets(expression, 4500, input) != NULL) {
	len = strlen(expression);
	len--;
	while ((len >= 0) &&
	       ((expression[len] == '\n') || (expression[len] == '\t') ||
		(expression[len] == '\r') || (expression[len] == ' '))) len--;
	expression[len + 1] = 0;
	if (len >= 0) {
	    printf("\n========================\nExpression: %s\n", expression) ;
	    testXPath(expression);
	}
    }

    fclose(input);
}

int main(int argc, char **argv) {
    int i;
    int strings = 0;
    int usefile = 0;
    char *filename = NULL;

    for (i = 1; i < argc ; i++) {
#if defined(LIBXML_XPTR_ENABLED)
	if ((!strcmp(argv[i], "-xptr")) || (!strcmp(argv[i], "--xptr")))
	    xptr++;
	else
#endif
	if ((!strcmp(argv[i], "-debug")) || (!strcmp(argv[i], "--debug")))
	    debug++;
	else if ((!strcmp(argv[i], "-valid")) || (!strcmp(argv[i], "--valid")))
	    valid++;
	else if ((!strcmp(argv[i], "-expr")) || (!strcmp(argv[i], "--expr")))
	    expr++;
	else if ((!strcmp(argv[i], "-tree")) || (!strcmp(argv[i], "--tree")))
	    tree++;
	else if ((!strcmp(argv[i], "-nocdata")) ||
		 (!strcmp(argv[i], "--nocdata")))
	    nocdata++;
	else if ((!strcmp(argv[i], "-i")) || (!strcmp(argv[i], "--input")))
	    filename = argv[++i];
	else if ((!strcmp(argv[i], "-f")) || (!strcmp(argv[i], "--file")))
	    usefile++;
    }
    if (valid != 0) xmlDoValidityCheckingDefaultValue = 1;
    xmlLoadExtDtdDefaultValue |= XML_DETECT_IDS;
    xmlLoadExtDtdDefaultValue |= XML_COMPLETE_ATTRS;
    xmlSubstituteEntitiesDefaultValue = 1;
#ifdef LIBXML_SAX1_ENABLED
    if (nocdata != 0) {
	xmlDefaultSAXHandlerInit();
	xmlDefaultSAXHandler.cdataBlock = NULL;
    }
#endif
    if (document == NULL) {
        if (filename == NULL)
	    document = xmlReadDoc(buffer,NULL,NULL,XML_PARSE_COMPACT);
	else
	    document = xmlReadFile(filename,NULL,XML_PARSE_COMPACT);
    }
    for (i = 1; i < argc ; i++) {
	if ((!strcmp(argv[i], "-i")) || (!strcmp(argv[i], "--input"))) {
	    i++; continue;
	}
	if (argv[i][0] != '-') {
	    if (usefile)
	        testXPathFile(argv[i]);
	    else
		testXPath(argv[i]);
	    strings ++;
	}
    }
    if (strings == 0) {
	printf("Usage : %s [--debug] [--copy] stringsorfiles ...\n",
	       argv[0]);
	printf("\tParse the XPath strings and output the result of the parsing\n");
	printf("\t--debug : dump a debug version of the result\n");
	printf("\t--valid : switch on DTD support in the parser\n");
#if defined(LIBXML_XPTR_ENABLED)
	printf("\t--xptr : expressions are XPointer expressions\n");
#endif
	printf("\t--expr : debug XPath expressions only\n");
	printf("\t--tree : reserved for the removed private compiled-tree dump\n");
	printf("\t--nocdata : do not generate CDATA nodes\n");
	printf("\t--input filename : or\n");
	printf("\t-i filename      : read the document from filename\n");
	printf("\t--file : or\n");
	printf("\t-f     : read queries from files, args\n");
    }
    if (document != NULL)
	xmlFreeDoc(document);
    xmlCleanupParser();
    xmlMemoryDump();

    return(0);
}
#else
#include <stdio.h>
int main(int argc ATTRIBUTE_UNUSED, char **argv ATTRIBUTE_UNUSED) {
    printf("%s : XPath/Debug support not compiled in\n", argv[0]);
    return(0);
}
#endif /* LIBXML_XPATH_ENABLED */
