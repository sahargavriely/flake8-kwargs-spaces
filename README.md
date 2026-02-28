[![github-workflow](https://github.com/sahargavriely/flake8-kwargs-spaces/actions/workflows/github-action.yml/badge.svg)](https://github.com/sahargavriely/flake8-kwargs-spaces/actions/workflows/github-action.yml)
[![codecov](https://codecov.io/gh/sahargavriely/flake8-kwargs-spaces/graph/badge.svg?token=W0V7MR7T8S)](https://codecov.io/gh/sahargavriely/flake8-kwargs-spaces)

# Flake8 Keyword Arguments with Spaces Plugin

The `flake8-kwargs-spaces` package is a plugin for Flake8 that enforces consistent spacing around the equals sign (`=`) in function arguments, in both definitions and calls. By integrating this plugin, developers can ensure uniform code formatting and adherence to style guidelines.

## Rules

- **Multiline:** When a keyword argument or default is on its own line (e.g. one argument under the `def` or call), use **spaces** around `=` → `key = 'val'`. Violations are reported as **EKS100**.
- **Inline:** When the argument is on the same line as the `def`/call, or when multiple keyword arguments appear on the same line, use **no spaces** around `=` → `key='val'`. Violations are reported as **EKS251**.

## Anti-pattern

```py
def foo(
    key='val'
):
    return key


foo(
    key='val'
)
```

## Best practice

```py
def foo(
    key = 'val'
):
    return key


foo(
    key = 'val'
)
```

### Still anti-pattern

```py
def foo(key = 'val'):
    return key


foo(key = 'val')
```

### Still best practice

```py
def foo(key='val'):
    return key


foo(key='val')
```

## Installation

**From PyPI** (once published):

```sh
pip install flake8-kwargs-spaces
```

**From source** (development or before first publish):

1. Clone the repository and enter it:

   ```sh
   git clone git@github.com:sahargavriely/flake8-kwargs-spaces.git
   cd flake8-kwargs-spaces
   ```

2. Run the installation script, then activate the virtual environment:

   ```sh
   ./scripts/install.sh
   source venv/bin/activate
   ```

3. (Optional) Run the test suite to verify everything works:

   ```sh
   pytest tests/
   ```

4. The install script builds a wheel under `wheels/`. To use the plugin with Flake8, install that wheel in the environment where you want the plugin enforced:

   ```sh
   pip install ./wheels/flake8_kwargs_spaces-0.1.0-py3-none-any.whl
   ```

5. To avoid conflicts with Flake8’s built-in E251 rule, add a `setup.cfg` (or use your existing one) with:

   ```ini
   [flake8]
   ignore = E251
   ```

## License

MIT. See [LICENSE](LICENSE).

## Thanks

- https://www.youtube.com/watch?v=ot5Z4KQPBL8
- https://www.youtube.com/watch?v=4L0Jb3Ku81s
- https://www.youtube.com/watch?v=GaWs-LenLYE
- https://www.youtube.com/watch?v=02aAZ8u3wEQ
