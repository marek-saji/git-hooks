#!/bin/sh
set -ue

# Unset in case we are running from `npm test`
unset INIT_CWD

# shellcheck disable=SC1090
package_dir="$( cd "$( dirname "$( readlink "$0" || echo "$0" )" )"; pwd -P )"
install="$package_dir/install.sh"

if [ -n "${DEBUG-}" ]
then
    test_dir="$PWD/test-env"
    rm -rf "$test_dir"
    mkdir -p "$test_dir"
else
    test_dir="$( mktemp -d )"
    trap 'rm -rf "$test_dir"' EXIT HUP INT QUIT TERM
fi
test_repo_dir="$test_dir/repo"
test_remote_dir="$test_dir/remote"

cd "$package_dir"

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
    git symbolic-ref HEAD refs/heads/main
    git config --local user.name "Tester McTestface"
    git config --local user.email "tester@example.com"
    git commit -m 'Root' --allow-empty --quiet
    git config --local hooks.verbosity 0
    git config --local hooks.pattern "$pattern"
    npm init --yes >/dev/null

    mkdir -p "$test_remote_dir"
    cd "$test_remote_dir"
    git clone --quiet --bare "file://$test_repo_dir/.git" .

    cd "$test_repo_dir"
    git remote add origin "file://$test_remote_dir"
    git fetch origin --quiet
    mkdir -p node_modules/.bin/
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
    git add "$@"
    git commit --quiet -m A 2>&1
}

push ()
{
    git add "$@"
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
    git add package.json
    git commit --no-verify -m package.json
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


TEST "pre-commit: git-check passing" "git-check"

printf 'This has no white space at the end of the line:' > foo
commit foo
OK


TEST "pre-commit: git-check failing" "git-check"

printf 'This has white space at the end of the line:    ' > foo
commit foo | assert_fail 'git-check'
OK


TEST "pre-commit: git-check temporary disable command" "git-check"

printf 'This has white space at the end of the line:    ' > foo
commit foo | tee -a /dev/stderr | grep -qE '^    "?(.*/)?git"? -c hooks.git-check=false "?commit'
OK


TEST "pre-commit: non-ascii-filenames passing" "non-ascii-filenames"

: > foo
commit foo
OK


TEST "pre-commit: non-ascii-filenames failing" "non-ascii-filenames"

: > 'fóó'
commit 'fóó' | assert_fail 'non-ascii-filenames'
OK


TEST "pre-push: npm-test" "npm-test"

set_npm_test 'true'
: > foo.js
push foo.js
OK


TEST "pre-push: npm-test: jest" "npm-test"

set_npm_test ": jest; sh -c 'echo \$* > ./out' --"
cat package.json
: > foo.js
push foo.js
grep ' --findRelatedTests.*foo.js' ./out
OK


TEST "pre-push: npm-test: worktree" "npm-test"

set_npm_test 'true'
git config --local hooks.tmpWorkspace true
git status --porcelain > "$test_dir/status"
: > foo.js
push foo.js
# Check for any unexpected artifacts
git status --porcelain | diff --report-identical-files "$test_dir/status" -
OK


TEST "Disablig all hooks" "git-check"

git config hooks.enabled false
printf 'This has white space at the end of the line:    ' > foo
commit foo
OK

TEST "Run commands from node_modules" "lint-eslint"

printf "#!/bin/sh\necho OK > ./eslint-called" > node_modules/.bin/eslint
chmod +x node_modules/.bin/eslint
: > foo.js
PATH=/bin:/usr/bin commit foo.js
test -e ./eslint-called
OK

CLEAN

ALL_DONE
