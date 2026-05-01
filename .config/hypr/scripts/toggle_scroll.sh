#!/bin/bash
if [ "$1" == "off" ]; then
    hyprctl keyword input:scroll_factor 0
else
    hyprctl keyword input:scroll_factor 1
fi
