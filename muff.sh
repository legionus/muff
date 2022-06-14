#!/bin/sh

cwd="$(realpath "$0")"
cwd="${cwd%/*}"

rc=0
"$cwd"/bin/muff || rc=$?

cat /tmp/muff.log

exit $rc
