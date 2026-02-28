"""
All code examples from flake8_kwargs_spaces tests.
Use for manual inspection or as a reference when running the linter.
"""


# Stubs so standalone snippets below don't trigger "not defined" in type checkers.
def f(*args: object, **kwargs: object): ...

a: object = None  # type: ignore[assignment]
kwargs: object = {}

# -----------------------------------------------------------------------------
# Trivial (no errors expected)
# -----------------------------------------------------------------------------

# (empty file)

f()

f(a)

f(**kwargs)


def f():
    pass


def f(a):
    pass


def f(**kwargs):
    pass


# -----------------------------------------------------------------------------
# Valid function CALLS (no errors)
# -----------------------------------------------------------------------------

f(no="spaces")

f(no="spaces", two="parameters")

f(no="spaces", two="parameters",
  upon="more", than="one_line")

f(
    yes = "spaces"
)

f(
    yes = "spaces",
    two = "parameters"
)

f(
    yes = "spaces",
    two = "parameters",
    everything="combine", final="form"
)

# -----------------------------------------------------------------------------
# Invalid function CALLS (errors expected)
# -----------------------------------------------------------------------------

f(left ="space")

f(right= "space")

f(two = "spaces")

f(
    more="than", one= "line"
)

f(
    left ="space"
)

f(
    right= "space"
)

f(
    both= "spaces"
)

f(left ="space", no="space",
  right= "space",
  two = "space",
  everything="combine", final="form"
)


# -----------------------------------------------------------------------------
# Valid function DEFINITIONS (no errors)
# -----------------------------------------------------------------------------


def f(no="spaces"):
    pass


def f(no="spaces", two="parameters"):
    pass


def f(no="spaces", two="parameters",
      upon="more", than="one_line"):
    pass


def f(
    yes = "spaces"
):
    pass


def f(
    yes = "spaces",
    two = "parameters"
):
    pass


def f(
    yes = "spaces",
    two = "parameters",
    everything="combine", final="form"
):
    pass


# -----------------------------------------------------------------------------
# Invalid function DEFINITIONS (errors expected)
# -----------------------------------------------------------------------------

def f(left ="space"):
    pass


def f(right= "spaces"):
    pass


def f(both = "spaces"):
    pass


def f(
    upon="more", than ="one"):
    pass


def f(
    left= "space"
):
    pass


def f(
    right ="space"
):
    pass


def f(
    yes = "spaces",
    two= "parameters"
):
    pass


# -----------------------------------------------------------------------------
# Valid async def (no errors)
# -----------------------------------------------------------------------------


async def f(no="spaces"):
    pass


async def f(
    yes = "spaces"
):
    pass


# -----------------------------------------------------------------------------
# Invalid async def (errors expected)
# -----------------------------------------------------------------------------


async def f(left ="space"):
    pass


async def f(
    x= 1
):
    pass


# -----------------------------------------------------------------------------
# Valid keyword-only def (no errors)
# -----------------------------------------------------------------------------


def f(*, a=1):
    pass


def f(*, no="spaces"):
    pass


def f(*,
    yes = "spaces"
):
    pass


# -----------------------------------------------------------------------------
# Invalid keyword-only def (errors expected)
# -----------------------------------------------------------------------------


def f(*, left ="space"):
    pass


def f(*,
    a= 1
):
    pass


# -----------------------------------------------------------------------------
# Valid positional-only def (no errors) — Python 3.8+
# -----------------------------------------------------------------------------


def f(a=1, /):
    pass


def f(a=1, /, b=2):
    pass


def f(
    a = 1, /
):
    pass


# -----------------------------------------------------------------------------
# Invalid positional-only def (errors expected) — Python 3.8+
# -----------------------------------------------------------------------------


def f(left ="space", /):
    pass


def f(
    x= 1, /
):
    pass
