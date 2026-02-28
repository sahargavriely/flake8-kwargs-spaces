#!/bin/bash -e

cd "$(dirname "${BASH_SOURCE[0]}")/.."

# Prefer python3 (common on Linux when python is missing or points elsewhere)
if command -v python3 &>/dev/null; then
    PYTHON=python3
elif command -v python &>/dev/null; then
    PYTHON=python
else
    echo "Error: No Python interpreter found. Please install Python 3 and ensure 'python3' or 'python' is on your PATH." >&2
    exit 1
fi

function main {
    "$PYTHON" -m pip install --upgrade pip
    if ! "$PYTHON" -m venv venv --prompt=flake8-kwargs-spaces; then
        echo "Error: Failed to create the virtual environment. The standard library 'venv' module may be missing." >&2
        echo "  On Debian/Ubuntu, install it with: sudo apt install python3-venv" >&2
        echo "  On Fedora/RHEL, install it with: sudo dnf install python3-virtualenv  (or yum)" >&2
        echo "  On macOS, ensure you have the Python 3 framework or run: python3 -m ensurepip" >&2
        exit 1
    fi
    find . -name site-packages -exec bash -c 'echo "../../../../" > {}/self.pth' \;
    venv/bin/pip install -U pip
    venv/bin/pip install -r requirements.txt
    venv/bin/pip wheel . -w wheels/
}

main "$@"
