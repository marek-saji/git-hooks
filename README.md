# git hooks

Zero config, opinionated git hooks that you can drop into your project
and it will just work™.

If there’s EsLint config, will lint your files, if there’s `test` npm
script will run it on push, if commit lint config, will check your
commit messages etc, etc, etc. For full list of hooks, see files in
`*.d` directories.

[![CI status](https://github.com/marek-saji/git-hooks/actions/workflows/test.yaml/badge.svg)](https://github.com/marek-saji/git-hooks/actions/workflows/test.yaml)

## Installation

### For everyone who clones your repository

Install hooks as a dependency in your project:

```sh
npm install --save-dev @saji/git-hooks
```

### For yourself

1. Install hooks package globally:

   ```sh
   npm install -g @saji/git-hooks
   ```

2. Install it in any repository you want:

   ```sh
   git install-hooks
   ```

   Add `-f` to force overwriting any existing hooks.

### Other methods

#### from cloned repository

1. Clone this repository somewhere

2. In your repository run:

   ```sh
   SOMEWHERE/install.sh`
   ```

#### by changing `hooksPath`

1. Clone this repository somewhere

2. In your repository run:

   ```sh
   git config core.hooksPath SOMEWHERE
   ```

   You could use `--global` to set it up for all your repositories.

## Configuration

### Disabling a hook

```sh
git config --type=int hooks.$HOOK_NAME.enabled false
# e.g. hooks.npm-test.enabled
```

You can also disable a hook for single run, e.g.

```sh
git -c hooks.npm-test.enabled=false push
```

As a shorthand you can omit `.enabled`:

```sh
git -c hooks.npm-test=false push
```

### Disabling all hooks

Apart from passing `--no-verify` you can also use `hooks.enabled`
config option.

### Changing verbosity

```sh
git config --type=int hooks.verbosity 2
```

- -1: Only error messages
- 0: Also show celebratory success message (default)
- 1: Also print hook names as they run
- 2: Also print hook execution time after they finish.
- 7: Also print main commands for some hooks
- 9: Also run everything with `set -x`

<!--
TODO If not specified in config, verbosity is controlled by number of `-v` parameter(s) passed to git-commit.
-->

<!-- TODO Rewrite this section, when worktree is properly implemented.
### Temporary worktree

```sh
git config --type=bool hooks.tmpWorkspace true
```

Some hooks might run for a longer time (e.g. `npm-test` pre-push). With
this option enabled, they might choose to run in a temporary worktree
(see `git worktree --help` to learn about git worktrees) so that your
main worktree is not blocked — you can switch branches, commit etc.
while your tests run.
-->

### Hook–specific options

#### pre-push: `npm-test`

Hook detects if [jest] is being used for testing and if so, only runs
tests that are related to modified files, but that heuristic is not
perfect. You can force selected files to always be included, e.g.

```sh
git config hooks.pre-push.npm-test.forcedJestTests tests/storybook.test.js
```

[jest]: https://jestjs.io/

#### pre-push: `branch-name`

When configured with a [extended grep regular expression] will check if
branch names match it, e.g.

```sh
git config hooks.pre-push.branch-name.allow-regexp '^((feat|fix|doc|chore)/|production$)'
```

You don’t have to list your main branch.

[extended grep regular expression]: https://www.gnu.org/software/grep/manual/grep.html#Basic-vs-Extended
