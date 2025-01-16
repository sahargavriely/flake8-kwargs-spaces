#!/bin/bash -e

function main {
    source venv/bin/activate
    venv/bin/python -m pytest --cov-report=html --cov-report=xml --cov-report=term --cov=flake8_kwargs_spaces tests/
    export TEST_RESULT=$?
    deactivate
    exit ${TEST_RESULT}
}

main "$@"
