#!/usr/bin/env sh

deps="perl6 git"
missDeps=""
for i in ${deps}; do
    which "${i}" &>/dev/null || missDeps="${i} ${missDeps}"
done
if test "${missDeps}" != "" ; then
    echo "missing depedencies:"
    echo ${missDeps}
    exit 1
else
    exit 0
fi