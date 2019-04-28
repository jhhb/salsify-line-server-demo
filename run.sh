#!/bin/bash
if [[ $# -eq 0 ]] ; then
    echo 'Must supply path of the file as first argument'
    echo 'Usage: sh run.sh <path_to_file>'
    exit 1
fi

args=("$@")

export FILE_PATH=${args[0]}
echo "Running server with FILE_PATH ${FILE_PATH}..."
export FILE_LINE_COUNT=`cat ${FILE_PATH} | wc -l`
echo "Calculated FILE_LINE_COUNT of ${FILE_LINE_COUNT} for FILE_PATH ${FILE_PATH}..."
redis-server &
echo "Started redis-server..."
bundle exec passenger start
echo "Started passenger..."
