#!/usr/bin/env python3

from __future__ import annotations

from pathlib import Path
from tempfile import TemporaryDirectory
import sys

import libxml2


class InlineResourceSchemaSuite:
    def __init__(
        self,
        *,
        conf: Path,
        log_name: str,
        instance_uses_dtd_prefix: bool,
        capture_errors: bool,
        substitute_entities: bool,
        quiet: int = 1,
        verbose: int = 0,
        debug: int = 0,
    ) -> None:
        self.conf = conf
        self.log = (Path.cwd() / log_name).open("w", encoding="utf-8")
        self.instance_uses_dtd_prefix = instance_uses_dtd_prefix
        self.capture_errors = capture_errors
        self.substitute_entities = substitute_entities
        self.quiet = quiet
        self.verbose = verbose
        self.debug = debug

        self.nb_schemas_tests = 0
        self.nb_schemas_success = 0
        self.nb_schemas_failed = 0
        self.nb_instances_tests = 0
        self.nb_instances_success = 0
        self.nb_instances_failed = 0
        self.resources: dict[str, str] = {}

    def error_handler(self, ctx, message):
        self.log.write(f"{ctx}{message}")

    @staticmethod
    def _node_markup(node) -> str:
        parts: list[str] = []
        child = node.children
        while child is not None:
            if child.type != "text":
                parts.append(child.serialize())
            child = child.next
        return "".join(parts)

    def _instance_markup(self, node) -> str:
        prefix = ""
        if self.instance_uses_dtd_prefix:
            prefix = node.prop("dtd") or ""
        return prefix + self._node_markup(node)

    def _resource_name(self, directory: str | None, name: str) -> str:
        if directory is None:
            return name
        return f"{directory}/{name}"

    def _write_resource_tree(self, root: Path, schema_text: str) -> Path:
        for name, content in self.resources.items():
            target = (root / name).resolve()
            if root.resolve() not in (target, *target.parents):
                raise ValueError(f"resource path escapes tempdir: {name}")
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(content, encoding="utf-8")

        schema_path = root / "main.rng"
        schema_path.write_text(schema_text, encoding="utf-8")
        return schema_path

    def _parse_schema(self, schema_text: str):
        with TemporaryDirectory(prefix="libxml-inline-suite-") as tmp:
            schema_path = self._write_resource_tree(Path(tmp), schema_text)
            try:
                pctxt = libxml2.relaxNGNewParserCtxt(str(schema_path))
                rngs = pctxt.relaxNGParse()
            except Exception:
                rngs = None
            return rngs

    def handle_valid(self, node, schema) -> None:
        instance = self._instance_markup(node)

        try:
            doc = libxml2.parseDoc(instance)
        except Exception:
            doc = None

        if doc is None:
            self.log.write("\nFailed to parse correct instance:\n-----\n")
            self.log.write(instance)
            self.log.write("\n-----\n")
            self.nb_instances_failed += 1
            return

        try:
            ctxt = schema.relaxNGNewValidCtxt()
            ret = doc.relaxNGValidateDoc(ctxt)
            del ctxt
        except Exception:
            ret = -1

        doc.freeDoc()

        if ret != 0:
            self.log.write("\nFailed to validate correct instance:\n-----\n")
            self.log.write(instance)
            self.log.write("\n-----\n")
            self.nb_instances_failed += 1
        else:
            self.nb_instances_success += 1

    def handle_invalid(self, node, schema) -> None:
        instance = self._instance_markup(node)

        try:
            doc = libxml2.parseDoc(instance)
        except Exception:
            doc = None

        if doc is None:
            self.log.write("\nStrange: failed to parse incorrect instance:\n-----\n")
            self.log.write(instance)
            self.log.write("\n-----\n")
            return

        try:
            ctxt = schema.relaxNGNewValidCtxt()
            ret = doc.relaxNGValidateDoc(ctxt)
            del ctxt
        except Exception:
            ret = -1

        doc.freeDoc()

        if ret == 0:
            self.log.write("\nFailed to detect validation problem in instance:\n-----\n")
            self.log.write(instance)
            self.log.write("\n-----\n")
            self.nb_instances_failed += 1
        else:
            self.nb_instances_success += 1

    def handle_correct(self, node):
        schema = self._node_markup(node)
        rngs = self._parse_schema(schema)
        if rngs is None:
            self.log.write("\nFailed to compile correct schema:\n-----\n")
            self.log.write(schema)
            self.log.write("\n-----\n")
            self.nb_schemas_failed += 1
        else:
            self.nb_schemas_success += 1
        return rngs

    def handle_incorrect(self, node):
        schema = self._node_markup(node)
        rngs = self._parse_schema(schema)
        if rngs is not None:
            self.log.write("\nFailed to detect schema error in:\n-----\n")
            self.log.write(schema)
            self.log.write("\n-----\n")
            self.nb_schemas_failed += 1
        else:
            self.nb_schemas_success += 1
        return None

    def handle_resource(self, node, directory: str | None) -> None:
        name = node.prop("name")
        if not name:
            self.log.write("resource has no name")
            return

        resource_name = self._resource_name(directory, name)
        self.resources[resource_name] = self._node_markup(node)

    def handle_dir(self, node, directory: str | None) -> None:
        name = node.prop("name")
        if not name:
            self.log.write("resource has no name")
            return

        next_dir = self._resource_name(directory, name)
        for child_dir in node.xpathEval("dir"):
            self.handle_dir(child_dir, next_dir)
        for resource in node.xpathEval("resource"):
            self.handle_resource(resource, next_dir)

    def handle_test_case(self, node) -> None:
        sections = node.xpathEval("string(section)")
        self.log.write(
            "\n    ======== test %d line %d section %s ==========\n"
            % (self.nb_schemas_tests, node.lineNo(), sections)
        )
        self.resources = {}

        if self.debug:
            print(f"test {self.nb_schemas_tests} line {node.lineNo()}")

        for directory in node.xpathEval("dir"):
            self.handle_dir(directory, None)
        for resource in node.xpathEval("resource"):
            self.handle_resource(resource, None)

        schema = None
        incorrect = node.xpathEval("incorrect")
        if incorrect:
            if len(incorrect) != 1:
                print(
                    f"warning test line {node.lineNo()} has more than one <incorrect> example"
                )
            schema = self.handle_incorrect(incorrect[0])
        else:
            correct = node.xpathEval("correct")
            if correct:
                if len(correct) != 1:
                    print(
                        f"warning test line {node.lineNo()} has more than one <correct> example"
                    )
                schema = self.handle_correct(correct[0])
            else:
                print(
                    f"warning <testCase> line {node.lineNo()} has no <correct> nor <incorrect> child"
                )

        self.nb_schemas_tests += 1

        valids = node.xpathEval("valid")
        invalids = node.xpathEval("invalid")
        self.nb_instances_tests += len(valids) + len(invalids)
        if schema is not None:
            for valid in valids:
                self.handle_valid(valid, schema)
            for invalid in invalids:
                self.handle_invalid(invalid, schema)

    def handle_test_suite(self, node, level: int = 0) -> None:
        if level >= 1:
            old_schemas_tests = self.nb_schemas_tests
            old_schemas_success = self.nb_schemas_success
            old_schemas_failed = self.nb_schemas_failed
            old_instances_tests = self.nb_instances_tests
            old_instances_success = self.nb_instances_success
            old_instances_failed = self.nb_instances_failed

        if self.quiet == 0:
            docs = node.xpathEval("documentation")
            authors = node.xpathEval("author")
            if docs:
                msg = "".join(f"{doc.content} " for doc in docs)
                if authors:
                    msg += "written by "
                    msg += "".join(f"{author.content} " for author in authors)
                print(msg)
            sections = node.xpathEval("section")
            if sections and level <= 0:
                msg = "".join(f"{section.content} " for section in sections)
                print(f"Tests for section {msg}")

        for test in node.xpathEval("testCase"):
            self.handle_test_case(test)
        for test in node.xpathEval("testSuite"):
            self.handle_test_suite(test, level + 1)

        if self.verbose and level >= 1:
            sections = node.xpathEval("section")
            if sections:
                msg = "".join(f"{section.content} " for section in sections)
                print(f"Result of tests for section {msg}")
                if self.nb_schemas_tests != old_schemas_tests:
                    print(
                        "found %d test schemas: %d success %d failures"
                        % (
                            self.nb_schemas_tests - old_schemas_tests,
                            self.nb_schemas_success - old_schemas_success,
                            self.nb_schemas_failed - old_schemas_failed,
                        )
                    )
                if self.nb_instances_tests != old_instances_tests:
                    print(
                        "found %d test instances: %d success %d failures"
                        % (
                            self.nb_instances_tests - old_instances_tests,
                            self.nb_instances_success - old_instances_success,
                            self.nb_instances_failed - old_instances_failed,
                        )
                    )

    def run(self) -> int:
        libxml2.debugMemory(1)
        libxml2.lineNumbersDefault(1)
        if self.capture_errors:
            libxml2.registerErrorHandler(self.error_handler, "")
        if self.substitute_entities:
            libxml2.substituteEntitiesDefault(1)

        testsuite = libxml2.parseFile(str(self.conf))
        root = testsuite.getRootElement()
        if root.name != "testSuite":
            print(f"{self.conf} doesn't start with a testSuite element, aborting")
            testsuite.freeDoc()
            self.log.close()
            return 1

        if self.quiet == 0:
            print("Running Relax NG testsuite")
        self.handle_test_suite(root)

        if self.quiet == 0:
            print("\nTOTAL:\n")
        if self.quiet == 0 or self.nb_schemas_failed != 0:
            print(
                "found %d test schemas: %d success %d failures"
                % (
                    self.nb_schemas_tests,
                    self.nb_schemas_success,
                    self.nb_schemas_failed,
                )
            )
        if self.quiet == 0 or self.nb_instances_failed != 0:
            print(
                "found %d test instances: %d success %d failures"
                % (
                    self.nb_instances_tests,
                    self.nb_instances_success,
                    self.nb_instances_failed,
                )
            )

        testsuite.freeDoc()
        self.log.close()

        libxml2.relaxNGCleanupTypes()
        libxml2.cleanupParser()

        failed = (self.nb_schemas_failed != 0) or (self.nb_instances_failed != 0)
        if libxml2.debugMemory(1) != 0:
            print(f"Memory leak {libxml2.debugMemory(1)} bytes")
            libxml2.dumpMemory()
            return 1
        return 1 if failed else 0


def run_inline_schema_suite(
    *,
    conf: Path,
    log_name: str,
    instance_uses_dtd_prefix: bool,
    capture_errors: bool,
    substitute_entities: bool,
    quiet: int = 1,
    verbose: int = 0,
    debug: int = 0,
) -> int:
    runner = InlineResourceSchemaSuite(
        conf=conf,
        log_name=log_name,
        instance_uses_dtd_prefix=instance_uses_dtd_prefix,
        capture_errors=capture_errors,
        substitute_entities=substitute_entities,
        quiet=quiet,
        verbose=verbose,
        debug=debug,
    )
    return runner.run()


if __name__ == "__main__":
    raise SystemExit("import and call run_inline_schema_suite()")
