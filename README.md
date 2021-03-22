git hooks
=========

Opinionated set of git hooks.

At the moment supports JavaScript, CSS, shell scripts and markdown files.


Installation
------------

### via npm dependency (recommended)

1. `npm install --save-dev @saji/git-hooks`
2. Add `install-git-hooks` to your `postinstall` script

### from global npm install

1. `npm install -g @saji/git-hooks`
2. Run `install-git-hooks PATH_TO_YOUR_PROJECT`

### from cloned repository

1. Clone this repository anywhere
2. Run `YOUR_ANYWHERE/install.sh PATH_TO_YOUR_PROJECT`

### by changing hooksPath

1. Clone this repository anywhere
2. Run `git config core.hooksPath YOUR_ANYWHERE/hooks`

### via whatever

You may also use git submodules. Or download files, drop them in your
`.git/hooks`, I don’t care.


Configuration
-------------

### Disabling a hook

    git config --type=int hooks.$HOOK_NAME.enabled false
    # e.g. hooks.lint.enabled

You can also disable a hook for single run, e.g.

    git -c hooks.npm-test.enabled=false push

As a shorthand you can omit `.enabled`:

    git -c hooks.npm-test=false push

### Disabling all hooks

Apart from passing `--no-verify` you can also use `hooks.enabled`
config option.

### Changing verbosity

    git config --type=int hooks.verbosity 2

- 0: Only error messages (default)
- 1: Also print hook names as they run
- 2: Also print main commands for some hooks
- 3: Also run everything with `set -x`

(TODO) If not specified in config, verbosity is controlled by number
of `-v` parameter(s) passed to git-commit.

### Temporary worktree

    git config --type=bool hooks.tmpWorkspace true

Some hooks might run for a longer time (e.g. npm-test pre-push). With
this option enabled, they might choose to run in a temporary worktree
(see `git worktree --help` for details) so that your main worktree is
not blocked — you can switch branches, commit etc. while your tests
run.


### Hooks

#### pre-push: npm-test

Detects if [jest] is being used for testing and if so, only runs tests
that are related to modified files, but that heuristic is not perfect.
This option enables you to additionally always run selected tests, e.g.

    git config hooks.pre-push.npm-test.forcedFiles tests/storybook.test.js


[jest]: https://jestjs.io/


#### pre-push: branch-name

Allows to set up a [extended grep regular expression] to match branches when pushing.

    git config hooks.pre-push.branch-name.allow-regexp '^(feature|fix|doc|chore)/'

You don’t have to list your main branch.


[extended grep regular expression]: https://www.gnu.org/software/grep/manual/grep.html#Basic-vs-Extended
