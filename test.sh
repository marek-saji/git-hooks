#!/bin/sh
set -ue

# shellcheck disable=SC1090
cd "$( dirname "$( readlink "$0" )" )"
test_dir="$PWD/tests-working-area"
install="$PWD/install.sh"

CLEAN ()
{
    cd "$test_dir/.."
    rm -rf "$test_dir"
}

TEST ()
{
    printf "\n## %s\n" "$1"
    CLEAN
    mkdir "$test_dir"
    cd "$test_dir"
    git init --quiet
    npm init --yes >/dev/null
    $install > /dev/null
}

OK ()
{
    printf "✅\n"
}

ALL_DONE ()
{
    printf "🎉\n"
}

assert_fail ()
{
    # shellcheck disable=SC1111
    grep -q "“$1” hook failed"
}

assert_no_fail ()
{
    # shellcheck disable=SC1111
    ! grep -q "“$1” hook failed"
}


TEST "Install"

test -x .git/hooks/pre-commit
test -x .git/hooks/pre-push
OK


TEST "Re–install"

$install
test -x .git/hooks/pre-commit
test -x .git/hooks/pre-push
OK


TEST "pre-commit: git-check"

printf 'This has white space at the end of the line:    ' > foo
git add .
git commit -m A 2>&1 | assert_fail 'git-check'
OK


CLEAN

ALL_DONE
