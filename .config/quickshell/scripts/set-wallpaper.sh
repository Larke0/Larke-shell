#!/usr/bin/env bash

WALLPAPER=$1

awww img "$WALLPAPER"

~/.config/quickshell/scripts/set-theme.sh

mkdir -p ~/.config/hypr/assets && ln -sf "$WALLPAPER" ~/.config/hypr/assets/wallpaper
