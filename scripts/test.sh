#!/bin/bash

SCRIPT_DIR=$(dirname "$0")

WINAS_LATEST=$(curl -s https://api.github.com/repos/aidingnan/winas/commits/master | jq '.sha')

if [[ ! "$WINAS_LATEST" =~ ^\"[a-f0-9]{40}\"$ ]]; then
  echo match
else
  echo mismatch
fi
