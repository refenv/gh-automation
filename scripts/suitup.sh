#!/usr/bin/env bash

# CIJOE setup: provides access to the CIJOE modules e.g. ssh::shell
cij_setup() {
  CIJ_ROOT=$(cij_root)
  export CIJ_ROOT

  pushd "$CIJ_ROOT" || exit 1
  source modules/cijoe.sh
  if ! source "$CIJ_ROOT/modules/cijoe.sh"; then
    echo "Bad mojo"
    exit
  fi
  popd || exit 1
}
cij_setup

# CIJOE setup: load the target-environment
if [[ -v TARGET_ENV ]]; then
  source $TARGET_ENV
fi
