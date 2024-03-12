#!/usr/bin/env zsh

# source setup.sh from same directory as this file
_SETUP_DIR=$(builtin cd -q "`dirname "$0"`" > /dev/null && pwd)
emulate -R zsh -c 'source "$_SETUP_DIR/build.sh"'
