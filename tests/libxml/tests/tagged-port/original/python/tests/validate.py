#!/usr/bin/python -u
import sys
import libxml2

# Memory debug specific
libxml2.debugMemory(1)

VALIDATE_OPTIONS = libxml2.XML_PARSE_DTDLOAD | libxml2.XML_PARSE_DTDVALID


def parse_with_validation(path):
    ctxt = libxml2.newParserCtxt()
    doc = ctxt.ctxtReadFile(path, None, VALIDATE_OPTIONS)
    return ctxt, doc

ctxt, doc = parse_with_validation("valid.xml")
valid = ctxt.isValid()

if doc.name != "valid.xml":
    print("doc.name failed")
    sys.exit(1)
root = doc.children
if root.name != "doc":
    print("root.name failed")
    sys.exit(1)
if valid != 1:
    print("validity chec failed")
    sys.exit(1)
doc.freeDoc()

i = 1000
while i > 0:
    ctxt, doc = parse_with_validation("valid.xml")
    valid = ctxt.isValid()
    doc.freeDoc()
    if valid != 1:
        print("validity check failed")
        sys.exit(1)
    i = i - 1

#deactivate error messages from the validation
def noerr(ctx, str):
    pass

libxml2.registerErrorHandler(noerr, None)

ctxt, doc = parse_with_validation("invalid.xml")
valid = ctxt.isValid()
if doc.name != "invalid.xml":
    print("doc.name failed")
    sys.exit(1)
root = doc.children
if root.name != "doc":
    print("root.name failed")
    sys.exit(1)
if valid != 0:
    print("validity chec failed")
    sys.exit(1)
doc.freeDoc()

i = 1000
while i > 0:
    ctxt, doc = parse_with_validation("invalid.xml")
    valid = ctxt.isValid()
    doc.freeDoc()
    if valid != 0:
        print("validity check failed")
        sys.exit(1)
    i = i - 1
del ctxt

# Memory debug specific
libxml2.cleanupParser()
if libxml2.debugMemory(1) == 0:
    print("OK")
else:
    print("Memory leak %d bytes" % (libxml2.debugMemory(1)))
    libxml2.dumpMemory()
