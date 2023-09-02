import ast
from typing import Set

import pytest

from flake8_kwargs_spaces import Plugin, missing_msg, unexpected_msg


valid_functions_call = [
    ("unexpected", [
        'f(no="spaces")',
        'f(no="spaces", two="parameters")',
        'f(no="spaces", two="parameters",\n\
            upon="more", than="one_line")',
    ]),
    ("missing", [
        'f(\n\
                yes = "spaces"\n\
        )',
        'f(\n\
                yes = "spaces",\n\
                two = "parameters"\n\
        )',
    ]),
    ("combine", [
        'f(\n\
                yes = "spaces",\n\
                two = "parameters",\n\
                everything="combine", final="form"\n\
        )',
    ]),
]
invalid_functions_call = [
    ("unexpected", [
        (1, 8, unexpected_msg, 'f(left ="space")'),
        (1, 9, unexpected_msg, 'f(right= "space")'),
        (1, 8, unexpected_msg, 'f(two = "spaces")'),
        (2, 30, unexpected_msg, 'f(\n\
            more="than", one= "line"\n\
                )'),
    ]),
    ("missing", [
        (2, 22, missing_msg, 'f(\n\
                left ="space"\n\
            )'),
        (2, 23, missing_msg, 'f(\n\
                right= "space"\n\
            )'),
        (2, 21, missing_msg, 'f(\n\
                both="spaces"\n\
            )'),
    ]),
]
valid_functions_def = [
    ("unexpected", [
        'def f(no="spaces"):\n\
               pass',
        'def f(no="spaces", two="parameters"):\n\
                pass',
        'def f(no="spaces", two="parameters",\n\
                upon="more", than="one_line"):\n\
                pass',
    ]),
    ("missing", [
        'def f(\n\
                yes = "spaces"\n\
            ):\n\
                pass',
        'def f(\n\
                yes = "spaces",\n\
                two = "parameters"\n\
            ):\n\
                pass',
    ]),
    ("combine", [
        'def f(\n\
                yes = "spaces",\n\
                two = "parameters",\n\
                everything="combine", final="form"\n\
            ):\n\
                pass',
    ]),
]
invalid_functions_def = [
    ("unexpected", [
        (1, 12, unexpected_msg, 'def f(left ="space"):\n\
               pass'),
        (1, 13, unexpected_msg, 'def f(right= "spaces"):\n\
                pass'),
        (1, 13, unexpected_msg, 'def f(both = "spaces"):\n\
                pass'),
        (2, 35, unexpected_msg, 'def f(\n\
                upon="more", than ="one"):\n\
                pass'),
    ]),
    ("missing", [
        (2, 22, missing_msg, 'def f(\n\
                left= "space"\n\
            ):\n\
                pass'),
        (2, 23, missing_msg, 'def f(\n\
                right ="space"\n\
            ):\n\
                pass'),
        (3, 21, missing_msg, 'def f(\n\
                yes = "spaces",\n\
                two= "parameters"\n\
            ):\n\
                pass'),
    ]),
]


def _results(s: str) -> Set[str]:
    tree = ast.parse(s)
    plugin = Plugin(tree)
    return {f'{line}:{col} {msg}' for line, col, msg, _ in plugin.run()}


def test_trivial_case():
    assert _results('') == set()


@pytest.mark.parametrize('case, valid_functions_call', valid_functions_call)
def test_valid_function_call(case, valid_functions_call):
    for func_call in valid_functions_call:
        ret = _results(func_call)
        assert ret == set()


@pytest.mark.parametrize('case, invalid_functions_call', invalid_functions_call)
def test_invalid_function_call(case, invalid_functions_call):
    for line, col, msg, func_call in invalid_functions_call:
        ret = _results(func_call)
        assert f'{line}:{col} {msg}' in ret


def test_combine_invalid_function_call():
    func_call = 'f(left ="space", no="space",\n\
            right= "space",\n\
            two = "space"\n\
        )'
    errors = [
        (1, 8, unexpected_msg),
        (2, 19, missing_msg),
    ]
    ret = _results(func_call)
    for line, col, msg in errors:
        assert f'{line}:{col} {msg}' in ret


@pytest.mark.parametrize('case, valid_functions_def', valid_functions_def)
def test_valid_function_def(case, valid_functions_def):
    for func_def in valid_functions_def:
        ret = _results(func_def)
        assert ret == set()


@pytest.mark.parametrize('case, invalid_functions_def', invalid_functions_def)
def test_invalid_function_def(case, invalid_functions_def):
    for line, col, msg, func_def in invalid_functions_def:
        ret = _results(func_def)
        assert f'{line}:{col} {msg}' in ret
