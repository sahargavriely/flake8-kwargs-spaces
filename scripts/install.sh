#!/bin/bash -e

cd "$(dirname "${BASH_SOURCE[0]}")/.."

function main {
    pip install --upgrade pip
    pip install virtualenv
    python -m venv venv --prompt=flake8-kwargs-spaces
    find . -name site-packages -exec bash -c 'echo "../../../../" > {}/self.pth' \;
    venv/bin/pip install -U pip
    venv/bin/pip install -r requirements.txt
    venv/bin/pip wheel . -w wheels/
}

main "$@"
