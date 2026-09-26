#! /bin/bash

cd "$PROJECT_PATH"
local_hash=$(git rev-parse HEAD)

#here's where claude helped
repo_hash=$(git ls-remote origin HEAD | awk '{print $1}')
# or:
#repo_hash=$(git ls-remote origin HEAD | cut -f1)
if [ "$local_hash" != "$repo_hash" ]; then
  echo "pulling"
	git pull
	#TODO: add webhook if all else works
fi