import ast
import importlib.metadata
from typing import Any
from typing import Generator
from typing import List
from typing import Tuple
from typing import Type


missing_msg = 'EKS100 missing whitespace around keyword / parameter equals'
unexpected_msg = 'EKS251 unexpected whitespace around keyword / parameter equals'


class Visitor(ast.NodeVisitor):
    def __init__(self) -> None:
        self.problems: List[Tuple[str, int, int]] = []

    def visit_Call(self, node: ast.Call) -> Any:
        lines = dict()
        for keyword in node.keywords:
            if keyword.lineno not in lines:
                lines[keyword.lineno] = list()
            lines.get(keyword.lineno).append((len(keyword.arg) + keyword.col_offset, keyword.value))
        self.visit_lines(lines, node.lineno)
        self.generic_visit(node)

    def visit_FunctionDef(self, node: ast.FunctionDef) -> Any:
        args = node.args
        lines = dict()
        for arg, default in zip(reversed(args.args), reversed(args.defaults)):
            if arg.lineno not in lines:
                lines[arg.lineno] = list()
            lines.get(arg.lineno).append((arg.end_col_offset, default))
        self.visit_lines(lines, node.lineno)
        self.generic_visit(node)

    def visit_lines(self, lines, func_line):
        for lineno, line in lines.items():
            if lineno == func_line or len(line) > 1:
                for end_arg, value in line:
                    self.unexpected_spaces(lineno, end_arg, value)
            else:
                end_arg, value = line[0]
                self.missing_spaces(lineno, end_arg, value)

    def missing_spaces(self, line, arg_end, value):
        if value.col_offset - arg_end < 3:
            self.problems.append((line, value.col_offset, missing_msg))

    def unexpected_spaces(self, line, arg_end, value):
        if value.col_offset - arg_end > 1:
            self.problems.append((line, value.col_offset, unexpected_msg))


class Plugin:
    name = __name__
    version = importlib.metadata.version(__name__)

    def __init__(self, tree: ast.AST) -> None:
        self._tree = tree

    def run(self) -> Generator[Tuple[int, int, str, Type[Any]], None, None]:
        visitor = Visitor()
        visitor.visit(self._tree)
        for line, col, msg in visitor.problems:
            yield line, col, msg, type(self)
