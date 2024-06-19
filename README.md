git hooks
=========

Opinionated set of git hooks.

At the moment supports JavaScript, CSS, shell scripts and markdown files.

[![npm package](https://img.shields.io/npm/v/@saji/git-hooks)](https://www.npmjs.com/package/@saji/git-hooks)
[![CI status](https://github.com/marek-saji/git-hooks/actions/workflows/test.yaml/badge.svg)](https://github.com/marek-saji/git-hooks/actions/workflows/test.yaml)


Installation
------------

### via npm dependency (recommended)

1. `npm install --save-dev @saji/git-hooks`
2. Add `git-install-hooks` to your `postinstall` script

### from global npm install

1. `npm install -g @saji/git-hooks`
2. Run `git-install-hooks PATH_TO_YOUR_PROJECT`

### from cloned repository

1. Clone this repository anywhere
2. Run `YOUR_ANYWHERE/install.sh PATH_TO_YOUR_PROJECT`

### by changing hooksPath

1. Clone this repository anywhere
2. Run `git config core.hooksPath YOUR_ANYWHERE`
   (use `git config --global` if you want to do it globally)

### via whatever

You may also use git submodules. Or download files, drop them in your
`.git/hooks`, I don’t care.


Configuration
-------------

### Disabling a hook

    git config --type=int hooks.$HOOK_NAME.enabled false
    # e.g. hooks.npm-test.enabled

You can also disable a hook for single run, e.g.

    git -c hooks.npm-test.enabled=false push

As a shorthand you can omit `.enabled`:

    git -c hooks.npm-test=false push

### Disabling all hooks

Apart from passing `--no-verify` you can also use `hooks.enabled`
config option.

### Changing verbosity

    git config --type=int hooks.verbosity 2

- -1: Only error messages
- 0: Also show celebratory success message (default)
- 1: Also print hook names as they run
- 2: Also print hook execution time after they finish.
- 7: Also print main commands for some hooks
- 9: Also run everything with `set -x`

(TODO) If not specified in config, verbosity is controlled by number
of `-v` parameter(s) passed to git-commit.

### Temporary worktree

    git config --type=bool hooks.tmpWorkspace true

Some hooks might run for a longer time (e.g. `npm-test` pre-push). With
this option enabled, they might choose to run in a temporary worktree
(see `git worktree --help` to learn about git worktrees) so that your
main worktree is not blocked — you can switch branches, commit etc.
while your tests run.


### Hook–specific options

#### pre-push: `npm-test`

Hook detects if [jest] is being used for testing and if so, only runs
tests that are related to modified files, but that heuristic is not
perfect. You can force selected files to always be included, e.g.

    git config hooks.pre-push.npm-test.forcedJestTests tests/storybook.test.js


[jest]: https://jestjs.io/


#### pre-push: `branch-name`

When configured with a [extended grep regular expression] will check if
branch names match it, e.g.

    git config hooks.pre-push.branch-name.allow-regexp '^(feat|fix|doc|chore)/'

You don’t have to list your main branch.


[extended grep regular expression]: https://www.gnu.org/software/grep/manual/grep.html#Basic-vs-Extended
