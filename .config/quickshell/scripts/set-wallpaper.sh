#!/bin/bash

WALLPAPER=$1

awww img "$WALLPAPER"

~/.config/quickshell/scripts/set-theme.sh

ln -sf "$WALLPAPER" ~/.config/hypr/assets/wallpaper
