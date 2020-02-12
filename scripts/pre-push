#!/bin/sh

# shellcheck disable=SC1090
. "$( dirname "$( readlink "$0" )" )/../lib/bootstrap"

REMOTE="$1"
URL="$2"

z40=0000000000000000000000000000000000000000

while read -r LOCAL_REF LOCAL_SHA REMOTE_REF REMOTE_SHA
do
    if [ "$LOCAL_SHA" = $z40 ]
    then
        # Handle delete
        ACTION=delete
        RANGE=
    else
        ACTION=push
        if [ "$REMOTE_SHA" = $z40 ]
        then
            # New branch, examine everything from base branch
            RANGE="$( git merge-base "$LOCAL_SHA" "$BASE_BRANCH@{u}" )..$LOCAL_SHA"
        else
            # Update to existing branch, examine new commits
            RANGE="$REMOTE_SHA..$LOCAL_SHA"
        fi
    fi

    export REMOTE URL
    export LOCAL_REF LOCAL_SHA REMOTE_REF REMOTE_SHA
    export ACTION RANGE

    run_hooks
done
