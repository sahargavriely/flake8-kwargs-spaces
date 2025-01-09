# Flake8 key world arguments with spaces Plugin

The `flake8-kwargs-spaces` package is a plugin for `flake8` that enforces consistent spacing around the equal sign (`=`) in function arguments, both in definitions and calls. It supports enforcing either spaces or no spaces, depending on the argument's position (inline or multi-line)  and the number of arguments in sequence. By integrating this plugin, developers can ensure uniform code formatting, enhancing readability and adherence to style guidelines.

## Good:

```
def f(
    a = 3
): ...


f(
    a = 3
)
```

### Still Good:

```
def f(a=3):
...


f(a=3)
```
    
## Bad:

```
def f(
    a=3
): ...


f(
    a=3
)
```

### Still Bad:

```
def f(a = 3):
...


f(a = 3)
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

    ```
    $ pytest tests/
    ...
    ```

4. Build and pack everything up by:

    ```sh
    $ ./scripts/build.sh
    ...
    ```

5. Boom, you have your wheel file under wheels directory ready to install wherever you want:

    ```sh
    $ pip install ./wheels/flake8_kwargs_spaces-0.1.0-py3-none-any.whl
    ...
    ```


#### Much thanks to:
    https://www.youtube.com/watch?v=ot5Z4KQPBL8
    https://www.youtube.com/watch?v=4L0Jb3Ku81s
    https://www.youtube.com/watch?v=GaWs-LenLYE
    https://www.youtube.com/watch?v=02aAZ8u3wEQ
