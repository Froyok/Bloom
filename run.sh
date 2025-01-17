#!/usr/bin/env bash
export PYTHONPYCACHEPREFIX="/tmp/python_temp/"
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Default is: llvm
export AMD_DEBUG=useaco

(cd "$SCRIPT_DIR/bin/12/linux/bin" && "./love" "$SCRIPT_DIR/data/")
