#!/bin/sh
set -e

print_help ()
{
    printf "Install git hooks in a repository.\n"
    printf "Usage: %s [TARGET_DIR]\n" "$0"
    printf "TARGET_DIR defaults to \$PWD.\n"
}

if [ "$1" = "-h" ] || [ "$1" = "--help" ]
then
    print_help
    exit 0
fi

dir="$( echo "${1:-$PWD}" | sed -E 's~.git(/hooks)?$~~' )"
git_dir="$( cd "$dir" && git rev-parse --absolute-git-dir )"
scripts_dir="$( cd "$( dirname "$0" )" && pwd -P )"

cd "$git_dir/hooks"
for name in pre-commit pre-push
do
    # TODO If exists and it’s not us -- print a warning
    if ! [ -e "$name" ]
    then
        ln -vs "$scripts_dir/$name" "$name"
    fi
done
