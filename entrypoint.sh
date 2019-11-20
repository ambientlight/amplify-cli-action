#!/bin/sh -l

set -e

if [ -z "$AWS_ACCESS_KEY_ID"] && [ -z "$AWS_SECRET_ACCESS_KEY" ]
then
  echo "You must provide the action with both AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables in order to deploy"
  exit 1
fi

if [ -z "$AWS_DEFAULT_REGION"]
then
  echo "You must provide AWS_DEFAULT_REGION in order to deploy"
fi

if [ -n "$1"]
then
  cd "$1"
fi

npm install

echo "$2"
echo "$3"
echo "$4"
