#!/bin/bash -e

function main {
    source venv/bin/activate
    export TEST_RESULT=$?
    deactivate
    exit ${TEST_RESULT}
}

main "$@"
