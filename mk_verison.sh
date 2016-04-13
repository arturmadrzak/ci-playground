#!/usr/bin/env bash

# Generate version header file.
# Version is encoded as:
# MAJOR_T_MINOR-GIT_HASH[-INDEX][-OWNER]
#
# note: _ is added to make pattern more clear. It is skipped.
#
# T - DELIMITER, this is image type (official release[.], release candidate [r] or development[d])
# GIT_HASH - is short hash of current commit
# INDEX - ommit if no changes made since last commit, dirty if any changes are made (staged or cached)
# OWNER - linux user name who made the build

function parse_base() {
    BASE=$(cat version.h | grep FW_VER | cut -f 3 -d' ' | sed s/\"//g | cut -f 1 -d '-')
    if [[ $BASE =~ ^([0-9]{1,2})([rd\.]{1})([0-9]{2})$ ]]; then
        MAJOR=${BASH_REMATCH[1]}
        DELIMITER=${BASH_REMATCH[2]}
        MINOR=${BASH_REMATCH[3]}
    else
        echo "ERROR: Current version string is incorrect " $BASE
        exit 1
    fi
}

function update_index_status() {
    if ! $(git diff --quiet --exit-code) || ! $(git diff --quiet --exit-code --cached) ; then
            INDEX='dirty'
    else
            INDEX=''
    fi
}

function update_git_short_hash() {
    GIT_HASH=`git rev-parse --short HEAD`
}

function determine_owner() {
    OWNER=$(whoami)
    # TODO: filter out travis-ci owner
}

function make_version_string() {
    VER=$(printf "%02d" $MAJOR)
    VER=$VER""$DELIMITER
    VER=$VER""$(printf "%02d" $MINOR)
    VER=$VER""-$GIT_HASH
    if [ -n "$INDEX" ]; then
        VER=$VER-$INDEX
    fi
    if [ -n "$OWNER" ]; then
        VER=$VER-$OWNER
    fi
}

function increment_version_master() {
    if [ $DELIMITER == '.' ]; then
        # this is hot fix commit
        let MINOR=MINOR+1
    elif [ $DELIMITER == 'r' ]; then
        # this is release candidate commit
        MINOR=00
        DELIMITER='.'
    else
        echo "Merging to master from other than release candidate is not allowed"
        exit 1
    fi
}

function increment_version_candidate() {
    # candidate is always forked form develop
    if [ $DELIMITER != 'd' ]; then
        echo "Release candidate can be forked only from develop"
        exit 1
    fi
    MINOR=00
    let MAJOR=MAJOR+1
    DELIMITER='r'
}

function increment_version_develop() {
    if [ $DELIMITER == 'r' ]; then
        # merge release candidate back to develop with all fixes
        MINOR=00
        DELIMITER='d'
    elif [ $DELIMITER == 'd' ]; then
        # normal development commit
        let MINOR=MINOR+1
    else
        echo "Merge from release candidate is allowed only"
        exit 1
    fi
}

function increment_version() {
   if [ $BRANCH == "master" ]; then
        increment_version_master
   elif [[ $BRANCH == "release*" ]]; then
        increment_version_candidate
    else
        increment_version_develop
    fi

}

parse_base
BRANCH=$(git rev-parse --abbrev-ref HEAD)
update_index_status
update_git_short_hash
determine_owner
increment_version
make_version_string

echo "BASE: $BASE"
echo $VER
