#!/bin/sh
set -o errexit -o verbose

test "$TRAVIS_TAG" &&
  mkdir -p "$HOME/.stack/upload" &&
  echo "{ \"username\": \"$HACKAGE_USERNAME\", \"password\": \"$HACKAGE_PASSWORD\" }" > "$HOME/.stack/upload/credentials.json" &&
  stack upload .
