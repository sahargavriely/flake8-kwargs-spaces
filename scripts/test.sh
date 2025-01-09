#!/bin/bash -e

function main {
    source venv/bin/activate
    export TEST_REULST=$?
    deactivate
    exit ${TEST_REULST}
}

main "$@"
