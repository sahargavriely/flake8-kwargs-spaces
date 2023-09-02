# Flake8 key world arguments with spaces Plugin

flake8 plugin for encouraging space engulfing of equal sign ( = ) in function calls and function definitions

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


f(a = 3)
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

### For usage purposes

You can go a head and download the wheel that located  in:
    ``flake8_kwargs_spaces-0.1.0-py3-none-any.whl``

Right after that all you want to do is install this wheel to your virtual environment (or to your global interpreter if you are trying to flatter me) by doing:
    ``pip install ...flake8_kwargs_spaces-0.1.0-py3-none-any.whl``

### For development purposes

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

3. To check that everything is working as expected, run the tests:

    ```
    $ pytest tests/
    ...
    ```

4. Develop, develop, develop (and test!)

5. Build and pack everything up by:

    ```sh
    $ pip wheel . -w wheels/
    ...
    ```

6. Boom, you have your whl file under wheels directory ready to install:

    ```sh
    $ pip install ...flake8_kwargs_spaces-0.1.0-py3-none-any.whl
    ...
    ```


#### Much thanks to:
    https://www.youtube.com/watch?v=ot5Z4KQPBL8
    https://www.youtube.com/watch?v=4L0Jb3Ku81s
    https://www.youtube.com/watch?v=GaWs-LenLYE
    https://www.youtube.com/watch?v=02aAZ8u3wEQ
