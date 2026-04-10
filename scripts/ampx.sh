#!/bin/sh
set -eu

NODE22_BIN="/opt/homebrew/opt/node@22/bin"

if [ -d "$NODE22_BIN" ]; then
  export PATH="$NODE22_BIN:$PATH"
fi

if [ "${AWS_PROFILE:-}" = "" ] && [ "${1:-}" != "configure" ]; then
  export AWS_PROFILE="amplify"
fi

npx ampx "$@"
