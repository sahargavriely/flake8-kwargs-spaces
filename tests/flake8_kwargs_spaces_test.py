import ast
import sys
from typing import Set

import pytest

from flake8_kwargs_spaces import Plugin, missing_msg, unexpected_msg


trivial = [
    '',  # no code
    # func call no kwargs
    'f()',
    'f(a)',
    'f(**kwargs)',
    # 'func def no kwargs
    'def f():\n\
        pass',
    'def f(a):\n\
        pass',
    'def f(**kwargs):\n\
        pass',
]
valid_functions_call = [
    # unexpected
    'f(no="spaces")',
    'f(no="spaces", two="parameters")',
    'f(no="spaces", two="parameters",\n\
       upon="more", than="one_line")',
    # missing
    'f(\n\
        yes = "spaces"\n\
    )',
    'f(\n\
        yes = "spaces",\n\
        two = "parameters"\n\
    )',
    # combine
    'f(\n\
        yes = "spaces",\n\
        two = "parameters",\n\
        everything="combine", final="form"\n\
    )',
]
invalid_functions_call = [
    # unexpected
    ([(1, 7, unexpected_msg)], 'f(left ="space")'),
    ([(1, 8, unexpected_msg)], 'f(right= "space")'),
    ([(1, 6, unexpected_msg)], 'f(two = "spaces")'),
    ([(2, 25, unexpected_msg)],
     'f(\n\
        more="than", one= "line"\n\
     )'),
    # missing
    ([(2, 13, missing_msg)],
     'f(\n\
        left ="space"\n\
     )'),
    ([(2, 14, missing_msg)],
     'f(\n\
        right= "space"\n\
     )'),
    ([(2, 13, missing_msg)],
     'f(\n\
        both="spaces"\n\
     )'),
    # combine
    (
        [
            (1, 7, unexpected_msg),
            (2, 17, missing_msg),
        ],
        'f(left ="space", no="space",\n\
           right= "space",\n\
           two = "space",\n\
           everything="combine", final="form"\n\
         )'
    ),
]
valid_functions_def = [
    # unexpected
    'def f(no="spaces"):\n\
        pass',
    'def f(no="spaces", two="parameters"):\n\
        pass',
    'def f(no="spaces", two="parameters",\n\
           upon="more", than="one_line"):\n\
        pass',
    # missing
    'def f(\n\
        yes = "spaces"\n\
    ):\n\
        pass',
    'def f(\n\
        yes = "spaces",\n\
        two = "parameters"\n\
    ):\n\
        pass',
    # combine
    'def f(\n\
        yes = "spaces",\n\
        two = "parameters",\n\
        everything="combine", final="form"\n\
    ):\n\
        pass',
]
invalid_functions_def = [
    # unexpected (col = 1-based, first column after arg name)
    ([(1, 11, unexpected_msg)],
     'def f(left ="space"):\n\
        pass'),
    ([(1, 12, unexpected_msg)],
     'def f(right= "spaces"):\n\
        pass'),
    ([(1, 11, unexpected_msg)],
     'def f(both = "spaces"):\n\
        pass'),
    ([(2, 26, unexpected_msg)],
     'def f(\n\
        upon="more", than ="one"):\n\
        pass'),
    # missing
    ([(2, 13, missing_msg)],
     'def f(\n\
        left= "space"\n\
     ):\n\
        pass'),
    ([(2, 14, missing_msg)],
     'def f(\n\
        right ="space"\n\
     ):\n\
        pass'),
    ([(3, 12, missing_msg)],
     'def f(\n\
        yes = "spaces",\n\
        two= "parameters"\n\
     ):\n\
        pass'),
]

valid_async_function_def = [
    # unexpected
    'async def f(no="spaces"):\n\
        pass',
    'async def f(no="spaces", two="parameters"):\n\
        pass',
    'async def f(no="spaces", two="parameters",\n\
           upon="more", than="one_line"):\n\
        pass',
    # missing
    'async def f(\n\
        yes = "spaces"\n\
    ):\n\
        pass',
    'async def f(\n\
        yes = "spaces",\n\
        two = "parameters"\n\
    ):\n\
        pass',
    # combine
    'async def f(\n\
        yes = "spaces",\n\
        two = "parameters",\n\
        everything="combine", final="form"\n\
    ):\n\
        pass',
]
invalid_async_function_def = [
    # unexpected (col = 1-based, first column after arg name)
    ([(1, 17, unexpected_msg)],
     'async def f(left ="space"):\n\
        pass'),
    ([(1, 18, unexpected_msg)],
     'async def f(right= "spaces"):\n\
        pass'),
    ([(1, 17, unexpected_msg)],
     'async def f(both = "spaces"):\n\
        pass'),
    ([(2, 26, unexpected_msg)],
     'async def f(\n\
        upon="more", than ="one"):\n\
        pass'),
    # missing
    ([(2, 13, missing_msg)],
     'async def f(\n\
        left= "space"\n\
     ):\n\
        pass'),
    ([(2, 14, missing_msg)],
     'async def f(\n\
        right ="space"\n\
     ):\n\
        pass'),
    ([(3, 12, missing_msg)],
     'async def f(\n\
        yes = "spaces",\n\
        two= "parameters"\n\
     ):\n\
        pass'),
]

valid_keyword_only_def = [
    # unexpected
    'def f(*, no="spaces"):\n\
        pass',
    'def f(*, no="spaces", two="parameters"):\n\
        pass',
    'def f(*, no="spaces", two="parameters",\n\
           upon="more", than="one_line"):\n\
        pass',
    # missing
    'def f(*,\n\
        yes = "spaces"\n\
    ):\n\
        pass',
    'def f(*,\n\
        yes = "spaces",\n\
        two = "parameters"\n\
    ):\n\
        pass',
    # combine
    'def f(*,\n\
        yes = "spaces",\n\
        two = "parameters",\n\
        everything="combine", final="form"\n\
    ):\n\
        pass',
]
invalid_keyword_only_def = [
    # unexpected (col = 1-based, first column after arg name)
    ([(1, 14, unexpected_msg)],
     'def f(*, left ="space"):\n\
        pass'),
    ([(1, 15, unexpected_msg)],
     'def f(*, right= "spaces"):\n\
        pass'),
    ([(1, 14, unexpected_msg)],
     'def f(*, both = "spaces"):\n\
        pass'),
    ([(2, 26, unexpected_msg)],
     'def f(*,\n\
        upon="more", than ="one"):\n\
        pass'),
    # missing
    ([(2, 13, missing_msg)],
     'def f(*,\n\
        left= "space"\n\
     ):\n\
        pass'),
    ([(2, 14, missing_msg)],
     'def f(*,\n\
        right ="space"\n\
     ):\n\
        pass'),
    ([(3, 12, missing_msg)],
     'def f(*,\n\
        yes = "spaces",\n\
        two= "parameters"\n\
     ):\n\
        pass'),
]

valid_positional_only_def = [
    # unexpected
    'def f(no="spaces", /):\n\
        pass',
    'def f(no="spaces", two="parameters", /):\n\
        pass',
    'def f(no="spaces", two="parameters",\n\
           upon="more", than="one_line", /):\n\
        pass',
    # missing
    'def f(\n\
        yes = "spaces", /\n\
    ):\n\
        pass',
    'def f(\n\
        yes = "spaces",\n\
        two = "parameters", /\n\
    ):\n\
        pass',
    # combine
    'def f(\n\
        yes = "spaces",\n\
        two = "parameters",\n\
        everything="combine", final="form", /\n\
    ):\n\
        pass',
]
invalid_positional_only_def = [
    # unexpected (col = 1-based, first column after arg name)
    ([(1, 11, unexpected_msg)],
     'def f(left ="space", /):\n\
        pass'),
    ([(1, 12, unexpected_msg)],
     'def f(right= "spaces", /):\n\
        pass'),
    ([(1, 11, unexpected_msg)],
     'def f(both = "spaces", /):\n\
        pass'),
    ([(2, 26, unexpected_msg)],
     'def f(\n\
        upon="more", than ="one", /):\n\
        pass'),
    # missing
    ([(2, 13, missing_msg)],
     'def f(\n\
        left= "space", /\n\
     ):\n\
        pass'),
    ([(2, 14, missing_msg)],
     'def f(\n\
        right ="space", /\n\
     ):\n\
        pass'),
    ([(3, 12, missing_msg)],
     'def f(\n\
        yes = "spaces",\n\
        two= "parameters", /\n\
     ):\n\
        pass'),
]


@pytest.mark.parametrize('case', trivial)
def test_trivial_case(case):
    _no_errors_assertions(case)


@pytest.mark.parametrize('case', valid_functions_call)
def test_valid_function_call(case):
    _no_errors_assertions(case)


@pytest.mark.parametrize('errors, case', invalid_functions_call)
def test_invalid_function_call(errors, case):
    _errors_assertions(errors, case)


@pytest.mark.parametrize('case', valid_functions_def)
def test_valid_function_def(case):
    _no_errors_assertions(case)


@pytest.mark.parametrize('errors, case', invalid_functions_def)
def test_invalid_function_def(errors, case):
    _errors_assertions(errors, case)


@pytest.mark.parametrize('case', valid_async_function_def)
def test_valid_async_function_def(case):
    _no_errors_assertions(case)


@pytest.mark.parametrize('errors, case', invalid_async_function_def)
def test_invalid_async_function_def(errors, case):
    _errors_assertions(errors, case)


@pytest.mark.parametrize('case', valid_keyword_only_def)
def test_valid_keyword_only_def(case):
    _no_errors_assertions(case)


@pytest.mark.parametrize('errors, case', invalid_keyword_only_def)
def test_invalid_keyword_only_def(errors, case):
    _errors_assertions(errors, case)


@pytest.mark.skipif(sys.version_info < (3, 8), reason='positional-only parameters require Python 3.8+')
@pytest.mark.parametrize('case', valid_positional_only_def)
def test_valid_positional_only_def(case):
    _no_errors_assertions(case)


@pytest.mark.skipif(sys.version_info < (3, 8), reason='positional-only parameters require Python 3.8+')
@pytest.mark.parametrize('errors, case', invalid_positional_only_def)
def test_invalid_positional_only_def(errors, case):
    _errors_assertions(errors, case)


def _no_errors_assertions(code):
    existing_errors = _extract_errors(code)
    assert not existing_errors


def _errors_assertions(expected_errors, code):
    existing_errors = _extract_errors(code)
    assert len(expected_errors) == len(existing_errors)
    for line, col, msg in expected_errors:
        assert f'{line}:{col} {msg}' in existing_errors


def _extract_errors(s: str) -> Set[str]:
    tree = ast.parse(s)
    plugin = Plugin(tree)
    return {f'{line}:{col} {msg}' for line, col, msg, _ in plugin.run()}
