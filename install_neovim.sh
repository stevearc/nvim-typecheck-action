#!/bin/bash
set -e

NVIM_TAG="$1"
if [ -z "$NVIM_TAG" ]; then
  NVIM_TAG=$(curl -s https://api.github.com/repos/neovim/neovim/releases/latest | jq -r .tag_name)
fi
echo "Installing Neovim $NVIM_TAG"
curl -sL "https://github.com/neovim/neovim/releases/download/${NVIM_TAG}/nvim.appimage" -o nvim.appimage
chmod +x nvim.appimage
./nvim.appimage --appimage-extract >/dev/null
rm -f nvim.appimage
mkdir -p ~/.local/share/nvim
mv squashfs-root ~/.local/share/nvim/appimage
sudo ln -s "$HOME/.local/share/nvim/appimage/AppRun" /usr/bin/nvim
