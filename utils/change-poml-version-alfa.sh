#!/bin/bash
version=`mvn -q -Dexec.executable="echo" -Dexec.args='${project.version}' --non-recursive org.codehaus.mojo:exec-maven-plugin:1.3.1:exec`
match_expression='^([0-9]*)\.([0-9]*)\.([0-9]*)-(.*)$'
new_version_string='NIGHTLY'

echo "$version"


if [[ $version =~ $match_expression ]]; then
    version=${BASH_REMATCH[1]}\.${BASH_REMATCH[2]}\.${BASH_REMATCH[3]}-${new_version_string}
fi

echo "$version"

mvn versions:set -DnewVersion=${version}
