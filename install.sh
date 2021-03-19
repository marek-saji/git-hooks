#!/bin/sh
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
git_dir="$(
    cd "$( echo "${1:-$PWD}" | sed -E 's~.git(/hooks)?$~~' )"
    git rev-parse --absolute-git-dir
)"
if ! [ -d "$git_dir" ]
then
    printf "Weird, git dir does not exist: %s\n" "$git_dir"
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
        target_hook_file="./$name"
        if [ -n "$ARG_FORCE" ]
        then
            ln -vsf "$source_hooks_dir/$name" "$target_hook_file"
        elif [ -h "$target_hook_file" ]
        then
            symlink_target="$( readlink "$target_hook_file" )"
            if [ -e "$target_hook_file" ]
            then
                printf "INFO %s hooks already exists (symlink to %s) — skipping.\n" "$name" "$symlink_target"
            else
                printf "WARNING %s hooks already exists (it’s a broken symlink to %s) — skipping.\n" "$name" "$symlink_target"
            fi
        elif [ -e "$target_hook_file" ]
        then
            printf "%s hook already exists (non-symlink file) — skipping.\n" "$name"
        else
            ln -vs "$source_hooks_dir/$name" "$target_hook_file"
        fi
    done
