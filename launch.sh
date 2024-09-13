#!/bin/sh
export LD_LIBRARY_PATH=/mnt/SDCARD/System/lib:/lib:/usr/lib:/usr/trimui/lib:/mnt/SDCARD/Apps/CollaGen/lib
export PATH="/bin:/usr/bin:/usr/local/bin:/mnt/SDCARD/System/bin"
appDir="$(cd "$(dirname "$0")" && pwd)"
"$appDir/TermSP" -k -f "$appDir/fonts/DejaVuSansMono.ttf" -b "$appDir/fonts/DejaVuSansMono-Bold.ttf" -s 20 -e "$appDir/collagen.sh"