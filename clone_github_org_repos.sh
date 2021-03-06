#!/bin/bash

set -e
set -u
set -x

source $(dirname $0)/.settings

GITHUB_API_BASE="api.github.com"
GITHUB_BASE="github.com"
GITHUB_SSH_USER="git"

clone() {

    export PKEY=$SSH_KEY

    url=$1
    org=$(echo $url | perl -ne 'm|([^/]+)/([^/]+)\.git| && print "$1\n"')
    repo=$(echo $url | perl -ne 'm|([^/]+)/([^/]+)\.git| && print "$2\n"')
    cwd=$(pwd)
    

    [ -d "${CLONE_DIR}/${org}" ] ||  mkdir "${CLONE_DIR}/${org}"

    if [ -d "${CLONE_DIR}/${org}/${repo}" ]
    then
        cd "${CLONE_DIR}/${org}/${repo}"
        git fetch --all 1>/dev/null
        git  pull --all  1>/dev/null
    else
        cd "${CLONE_DIR}/${org}"
        git clone ${GITHUB_SSH_USER}@${GITHUB_BASE}:${org}/$repo.git 
    fi

    cd $cwd
}

if [ "$#" == 0 ]
then
    echo "USAGE: $0 Org1 Org2 Org3....OrgN"
    exit 1
fi 

[ -d "$CLONE_DIR" ] || mkdir $CLONE_DIR


for org_name in $@
do
    clone_list=$( mktemp -t gitclone.XXXXXXX )
    base_url="https://${GITHUB_API_BASE}/orgs/${org_name}/repos"
    curl -u "${TOKEN}:x-oauth-basic"  "$base_url" 2>/dev/null > $clone_list
    for x in $( perl -ne 'm|\"clone_url\"\:\s+\"(.+)\"| && print "$1\n"' $clone_list)
    do
        echo $x
        clone $x
    done
    #rm $clone_list
done

