git hooks
=========

Installation
------------

### via script

1. Clone this repository anywhere
2. Run `scripts/install.sh PATH_TO_YOUR_PROJECT`

### via npm–installed script

1. `npm install -g @saji/git-hooks` (TODO)
2. Run `install-git-hooks PATH_TO_YOUR_PROJECT`

### via npm dependency

1. `npm install @saji/git-hooks` (TODO)
2. Add `install-git-hooks` to your `postinstall` script

### via whatever

You may also use git submodules. Or download files, drop them in your
`.git/hooks`, I don’t care.


Configuration
-------------

1. Disabling a hook

       git config --type=int hooks.$HOOK_TYPE.$HOOK_NAME.enabled false
       # e.g. hooks.pre-commit.lint.enabled

2. Changing verbosity

       git config --type=int hooks.verbosity 2

   - 0: Only error messages (default)
   - 1: Also print hook names as then run
   - 2: Also print main commands for some hooks
   - 3: Also run everything with `set -x`

   (TODO) If not specified in config, verbosity is controlled by number
   of `-v` parameter(s) passed to git-commit.


### pre-push npm-test

This hook detects if [jest] is being used for testing and if so, only
runs tests that are related to modified files, but that heuristic is not
perfect. This option enables you to additionally always run selected
tests, e.g.

    git config hooks.pre-push.test.forcedFiles tests/storybook.test.js


[jest]: https://jestjs.io/
[`--findRelatedTests`]: https://jestjs.io/docs/en/cli#--findrelatedtests-spaceseparatedlistofsourcefiles
