#!/bin/sh
set -ue

print_help ()
{
    printf "Install git hooks in a repository.\n"
    printf "Usage: %s [TARGET_DIR]\n" "$0"
    printf "TARGET_DIR defaults to \$PWD.\n"
}

get_package_name ()
{
    dir="$1"

    node -e '
        var path = require("path");
        var packageJson = require(process.argv[1]);
        process.stdout.write(packageJson.name);
    ' -- "$dir/package.json"
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]
then
    print_help
    exit 0
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
    cd "$( echo "$dir" | sed -E 's~.git(/hooks/?)?$~~' )"
    git rev-parse --absolute-git-dir
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
    [ "$npm_package_name" = "$( get_package_name "$dir" )" ]
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
        if [ -e "$target_hook_file" ]
        then
            printf "%s hook already exists — skipping.\n" "$name"
        elif [ -h "$target_hook_file" ]
        then
            printf "WARNING %s hooks already exists (but it’s a broken symlink) — skipping.\n" "$name"
        else
            ln -vs "$source_hooks_dir/$name" "$target_hook_file"
        fi
    done
