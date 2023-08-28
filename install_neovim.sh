#!/bin/bash
set -e

NVIM_TAG="${1-stable}"
echo "Installing Neovim $NVIM_TAG"
curl -sL "https://github.com/neovim/neovim/releases/download/${NVIM_TAG}/nvim.appimage" -o nvim.appimage
chmod +x nvim.appimage
./nvim.appimage --appimage-extract >/dev/null
rm -f nvim.appimage
mkdir -p ~/.local/share/nvim
mv squashfs-root ~/.local/share/nvim/appimage
sudo ln -s "$HOME/.local/share/nvim/appimage/AppRun" /usr/bin/nvim
/usr/bin/nvim --version
