#!/bin/bash
set -e

VERSION="$1"
mkdir -p ~/.local/share/language-servers/lua-language-server
cd ~/.local/share/language-servers/lua-language-server
if [ -z "$VERSION" ]; then
  VERSION=$(curl -s https://api.github.com/repos/LuaLS/lua-language-server/releases/latest | jq -r .tag_name)
fi
curl -sL "https://github.com/LuaLS/lua-language-server/releases/download/${VERSION}/lua-language-server-${VERSION}-linux-x64.tar.gz" -o lua-language-server.tar.gz
tar -zxf lua-language-server.tar.gz
rm -f lua-language-server.tar.gz
