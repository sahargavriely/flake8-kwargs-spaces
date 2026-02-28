import ast
import importlib.metadata
from typing import Any, Dict, Generator, List, Tuple, Type


missing_msg = 'EKS100 missing whitespace around keyword / parameter equals'
unexpected_msg = 'EKS251 unexpected whitespace around keyword / parameter equals'


def _default_pairs_from_args(args: ast.arguments) -> List[Tuple[ast.arg, ast.expr]]:
    '''Return (arg, default) for every parameter that has a default.'''
    pairs: List[Tuple[ast.arg, ast.expr]] = []
    # Positional and positional-or-keyword: defaults apply to rightmost of (posonlyargs + args)
    positional_only = getattr(args, 'posonlyargs', [])
    all_positional = positional_only + args.args
    if args.defaults:
        for arg, default in zip(reversed(all_positional), reversed(args.defaults)):
            pairs.append((arg, default))
    # Keyword-only: each kwonlyarg can have a default in kw_defaults (None = no default)
    for arg, default in zip(args.kwonlyargs, args.kw_defaults):
        if default is not None:
            pairs.append((arg, default))
    return pairs


LinesMap = Dict[int, List[Tuple[int, ast.expr]]]


class Visitor(ast.NodeVisitor):
    def __init__(self) -> None:
        self.problems: List[Tuple[int, int, str]] = []  # (lineno, col_offset, message)

    def visit_Call(self, node: ast.Call) -> Any:
        lines: LinesMap = {}
        for keyword in node.keywords:
            if keyword.arg is None:
                continue
            if keyword.lineno not in lines:
                lines[keyword.lineno] = []
            lines[keyword.lineno].append((len(keyword.arg) + keyword.col_offset, keyword.value))
        self.visit_lines(lines, node.lineno)
        self.generic_visit(node)

    def _visit_function_def(
        self, node: ast.FunctionDef | ast.AsyncFunctionDef
    ) -> None:
        lines: LinesMap = {}
        for arg, default in _default_pairs_from_args(node.args):
            if arg.lineno not in lines:
                lines[arg.lineno] = []
            lines[arg.lineno].append((arg.end_col_offset, default))
        self.visit_lines(lines, node.lineno)

    def visit_FunctionDef(self, node: ast.FunctionDef) -> Any:
        self._visit_function_def(node)
        self.generic_visit(node)

    def visit_AsyncFunctionDef(self, node: ast.AsyncFunctionDef) -> Any:
        self._visit_function_def(node)
        self.generic_visit(node)

    def visit_lines(self, lines: LinesMap, func_line: int) -> None:
        for lineno, line in lines.items():
            if lineno == func_line or len(line) > 1:
                for end_arg, value in line:
                    self.unexpected_spaces(lineno, end_arg, value)
            else:
                end_arg, value = line[0]
                self.missing_spaces(lineno, end_arg, value)

    def missing_spaces(
        self, line: int, arg_end: int, value: ast.expr
    ) -> None:
        if value.col_offset - arg_end < 3:
            self.problems.append((line, value.col_offset, missing_msg))

    def unexpected_spaces(
        self, line: int, arg_end: int, value: ast.expr
    ) -> None:
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
