#!/bin/bash -e

cd "$(dirname "${BASH_SOURCE[0]}")/.."

function main {
    venv/bin/pip wheel . -w wheels/
}

main "$@"
