[![github-workflow](https://github.com/sahargavriely/flake8-kwargs-spaces/actions/workflows/github-action.yml/badge.svg)](https://github.com/sahargavriely/flake8-kwargs-spaces/actions/workflows/github-action.yml)
[![codecov](https://codecov.io/gh/sahargavriely/flake8-kwargs-spaces/graph/badge.svg?token=W0V7MR7T8S)](https://codecov.io/gh/sahargavriely/flake8-kwargs-spaces)

# Flake8 key world arguments with spaces Plugin

The `flake8-kwargs-spaces` package is a plugin for `flake8` that enforces consistent spacing around the equal sign (`=`) in function arguments, both in definitions and calls. It supports enforcing either spaces or no spaces, depending on the argument's position (inline or multi-line)  and the number of arguments in sequence. By integrating this plugin, developers can ensure uniform code formatting, enhancing readability and adherence to style guidelines.
    
## Anti-pattern:

```py
def foo(
    key='val'
):
    return key


foo(
    key='val'
)
```

## Best practice:

```py
def foo(
    key = 'val'
):
    return key


foo(
    key = 'val'
)
```

### Still anti-pattern:

```py
def foo(key = 'val'):
    return key


foo(key = 'val')
```

### Still best practice:

```py
def foo(key='val'):
    return key


foo(key='val')
```

## Installation

1. Clone the repository and enter it:

    ```sh
    $ git clone git@github.com:sahargavriely/flake8-kwargs-spaces.git
    ...
    $ cd flake8-kwargs-spaces/
    ```

2. Run the installation script and activate the virtual environment according to your operating system:

    ```sh
    $ ./scripts/install.sh
    ...
    $ source .env/bin/activate
    [flake8-kwargs-spaces] $  # you're good to go!
    ```

3. To check that everything is working as expected, run the tests, or skip that, I'm not your mother:

    ```sh
    $ pytest tests/
    ...
    ```

5. Under `wheels` directory you should be able to find a `whl` file by the name of `flake8_kwargs_spaces-0.1.0-py3-none-any.whl`. In order to add this plugin to `flake8` you should pip install that file to wherever you want it to be enforced. The commend while look like this:

    ```sh
    $ pip install ./wheels/flake8_kwargs_spaces-0.1.0-py3-none-any.whl
    ...
    ```

6. In addition you will want to ignore `E251` - "Unexpected spaces around keyword / parameter equals", so you will want to add a file by the name of `setup.cfg` and inside it you should put the following:

    ```
    [flake8]
    ignore = E251
    ```

#### Much thanks to:
    https://www.youtube.com/watch?v=ot5Z4KQPBL8
    https://www.youtube.com/watch?v=4L0Jb3Ku81s
    https://www.youtube.com/watch?v=GaWs-LenLYE
    https://www.youtube.com/watch?v=02aAZ8u3wEQ
