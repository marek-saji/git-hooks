#!/bin/sh
set -ue

# Unset in case we are running from `npm test`
unset INIT_CWD

# shellcheck disable=SC1090
cd "$( dirname "$( readlink "$0" )" )"
install="$PWD/install.sh"

test_dir="$( mktemp -d )"

CLEAN ()
{
    cd "$( dirname "$test_dir" )"
    rm -rf "$test_dir"
}

TEST ()
{
    printf "\n## %s\n\n" "$1"
    CLEAN
    mkdir "$test_dir"
    cd "$test_dir"
    git init --quiet
    git symbolic-ref HEAD refs/heads/main
    git config --local user.name "Tester McTestface"
    git config --local user.email "tester@example.com"
    git commit -m 'Root' --allow-empty --quiet
    git config --local hooks.verbosity 0
    npm init --yes >/dev/null
    $install > /dev/null
    set -x
}

OK ()
{
    set +x
    printf "✅\n"
}

ALL_DONE ()
{
    printf "🎉\n"
}

assert_fail ()
{
    # shellcheck disable=SC1111
    tee -a /dev/stderr | grep -q "“$1” hook failed"
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


TEST "Disablig all hooks" "git-check"

git config --local hooks.enabled false
printf 'This has white space at the end of the line:    ' > foo
commit
OK


CLEAN

ALL_DONE
