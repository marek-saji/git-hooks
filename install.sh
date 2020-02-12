#!/bin/sh
set -e

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

if [ "$1" = "-h" ] || [ "$1" = "--help" ]
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

dir="$( echo "${1:-${INIT_CWD:-$PWD}}" | sed -E 's~.git(/hooks)?$~~' )"
package_dir="$( cd "$( dirname "$( realpath "$0" )" )" && pwd -P )"

# shellcheck disable=SC2154
if [ "$npm_config_global" = "true" ]
then
    # Ran `npm install -g` and postinstall kicked in
    exit 0
fi

# shellcheck disable=SC2154
if
    [ -n "$npm_package_name" ] &&
    [ "$npm_package_name" = "$( get_package_name "$dir" )" ]
then
    # Ran `npm install` in this package and postinstall kicked in
    exit 0
fi


# FIXME git dir might not exist
git_dir="$( cd "$dir" && git rev-parse --absolute-git-dir )"
hooks_dir="$package_dir/hooks"

# FIXME hooks dir might not exist
cd "$git_dir/hooks"
for name in pre-commit pre-push
do
    # TODO If exists and it’s not us -- print a warning
    if ! [ -e "$name" ]
    then
        ln -vs "$hooks_dir/$name" "$name"
    fi
done
