#!/usr/bin/env sh
set -ue

print_help ()
{
    printf "Install git hooks in a repository.\n"
    printf "Usage: %s [--force] [TARGET_DIR]\n" "$0"
    printf "Existing hooks will be skipped, unles --force is given.\n"
    printf "TARGET_DIR defaults to \$PWD.\n"
}

get_package_name ()
{
    dir="$1"

    if [ -e "$dir/package.json" ] && command -v node >/dev/null
    then
        node -e '
            process.stdout.write(require(process.argv[1]).name);
        ' -- "$dir/package.json"
    fi
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]
then
    print_help
    exit 0
fi

ARG_FORCE=
if [ "${1:-}" = "-f" ] || [ "${1:-}" = "--force" ]
then
    ARG_FORCE=1
    shift
fi

if ! command -v realpath >/dev/null
then
    realpath ()
    {
        (
            path="$1"
            cd "$( dirname "$path " )"
            while [ -h "$path" ]
            do
                path="$( readlink "$path" )"
                cd "$( dirname "$path" )"
            done
            echo "$PWD/$( basename "$path" )"
        )
    }
fi

package_dir="$( cd "$( dirname "$( realpath "$0" )" )" && pwd -P )"

dir="${1:-${INIT_CWD:-$PWD}}"
git_dir="$(
    cd "$dir"
    cd "$( git rev-parse --git-dir )"
    pwd -P
)"
if [ -z "$git_dir" ]
then
    printf "ERROR: No git repository found in: %s\n" "$dir"
    exit 66
fi

if [ "${npm_config_global:-}" = "true" ]
then
    # Ran `npm install -g` and postinstall kicked in
    exit 0
fi

if
    [ -n "${npm_package_name:-}" ] &&
    [ "$npm_package_name" = "$( get_package_name "$git_dir" )" ]
then
    # Ran `npm install` in this package and postinstall kicked in
    exit 0
fi

source_hooks_dir="$package_dir/hooks"
target_source_hooks_dir="$git_dir/hooks"

mkdir -p "$target_source_hooks_dir"
cd "$target_source_hooks_dir"
find "$source_hooks_dir" -type f |
    while read -r path
    do
        name="$( basename "$path" )"
        source_hook_file="$source_hooks_dir/$name"
        target_hook_file="./$name"

        # Instead of linking, we create small scripts that source the
        # hook files. This is, because some other hooks (e.g. lefthook)
        # tend to change contents of hook files when they install
        # themselves.

        if [ -n "$ARG_FORCE" ]
        then
            rm -fv "$target_hook_file"
        fi

        if [ -e "$target_hook_file" ]
        then
            printf "%s hook already exists — skipping.\n" "$name"
        else
            # shellcheck disable=SC2016
            printf '#!/usr/bin/env sh\nset -eu\n\nexport GIT_PID="$PPID"\nexport HOOKS_DIR="%s"\n. "%s" "$@"\n' \
                "$package_dir" \
                "$source_hook_file" \
                > "$target_hook_file"
            chmod +x "$target_hook_file"
        fi
    done

hookspath="$( git config --get core.hookspath || : )"
if [ -n "$hookspath" ] && [ "$hookspath" != ".git/hooks/" ]
then
    if ! git config --global core.hookspath >/dev/null
    then
        printf "core.hookspath was set to '%s', unsetting.\n" "$hookspath"
        git config --unset core.hookspath
    else
        printf "core.hookspath was set to '%s', changing to '.git/hooks/'\n" "$hookspath"
        git config core.hookspath '.git/hooks/'
    fi
fi
