#!/bin/sh

if [ -z "$APPDIR" ]; then
    APPDIR="$(dirname "$(readlink -f "$0")")"
fi

export LD_LIBRARY_PATH="$APPDIR/lib/:$LD_LIBRARY_PATH"

if [ -z "$XDG_DATA_DIRS" ]; then #unset or empty
    XDG_DATA_DIRS="/usr/local/share/:/usr/share/"
fi
export XDG_DATA_DIRS="$APPDIR/share/:$XDG_DATA_DIRS"

if [ -z "$LUA_PATH" ]; then
    LUA_PATH=";" # so ends with ;;
fi
# if user's LUA_PATH does not end with ;; then user doesn't want the default path ?
export LUA_PATH="$APPDIR/share/luajit-2.1.0-beta3/?.lua;$APPDIR/share/lua/5.1/?.lua;$LUA_PATH"

if [ -z "$LUA_CPATH" ]; then
    LUA_CPATH=";"
fi
export LUA_CPATH="$APPDIR/lib/lua/5.1/?.so;$LUA_CPATH"

# uncomment and edit to add your own game
#FUSE_PATH="$APPDIR/my_game.love"
#FUSE_PATH="$APPDIR/my_game"

if [ -z "$FUSE_PATH" ]; then
    exec "$APPDIR/bin/love" "$@"
else
    exec "$APPDIR/bin/love" --fused "$FUSE_PATH" "$@"
fi
