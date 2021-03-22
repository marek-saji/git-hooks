#!/bin/sh
set -ue

# shellcheck disable=SC1090
package_dir="$( cd "$( dirname "$( readlink "$0" )" )"; pwd -P )"
cd "$package_dir"
test_dir="$package_dir/tests-working-area"
test_repo_dir="$test_dir/repo"
test_remote_dir="$test_dir/remote"
install="$package_dir/install.sh"

CLEAN ()
{
    cd "$package_dir"
    rm -rf "$test_dir"
}

TEST ()
{
    name="$1"
    pattern="${2:-.*}"

    printf "\n## %s\n\n" "$name"
    CLEAN

    mkdir -p "$test_repo_dir"
    cd "$test_repo_dir"
    git init --quiet
    git commit -m 'Root' --allow-empty --quiet
    git config user.name "Tester McTestface"
    git config user.email "tester@example.com"
    git config hooks.verbosity 0
    git config hooks.pattern "$pattern"
    npm init --yes >/dev/null

    mkdir -p "$test_remote_dir"
    cd "$test_remote_dir"
    git clone --quiet --bare "file://$test_repo_dir/.git" .

    cd "$test_repo_dir"
    git remote add origin "file://$test_remote_dir"
    git fetch origin --quiet
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

commit ()
{
    git add .
    git commit --quiet -m A 2>&1
}

push ()
{
    git add .
    git commit --no-verify --quiet -m A 2>&1
    git push --quiet -u origin main 2>&1
}

assert_fail ()
{
    # shellcheck disable=SC1111
    tee -a /dev/stderr | grep -q "“$1” hook failed"
}

set_npm_test ()
{
    cmd="$1"
    printf '{"scripts": {"test": "%s"}}' "$cmd" > package.json
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


TEST "pre-commit: git-check" "git-check"

printf 'This has white space at the end of the line:    ' > foo
commit | assert_fail 'git-check'
OK


TEST "pre-push: npm-test" "npm-test"

set_npm_test 'true'
: > foo.js
push
OK


TEST "pre-push: npm-test: jest" "npm-test"

set_npm_test ": jest; sh -c 'echo \$* > ./out' --"
cat package.json
: > foo.js
push
grep ' --findRelatedTests.*foo.js' ./out
OK


TEST "pre-push: npm-test: worktree" "npm-test"

set_npm_test 'true'
git config hooks.tmpWorkspace true
: > foo.js
push
OK


TEST "Disablig all hooks" "git-check"

git config hooks.enabled false
printf 'This has white space at the end of the line:    ' > foo
commit
OK


CLEAN

ALL_DONE
