#!/bin/bash
# Dev tool: render the autopilot with Godot's Movie Maker (software GL under Xvfb)
# and encode an MP4. Usage: tools/capture.sh OUT.mp4 CAM SECONDS [extra user args]
set -euo pipefail
OUT=$1; CAM=${2:-cycle}; SECS=${3:-12}; shift 3 || true
GODOT=${GODOT:-godot}
FPS=30
TMP=$(mktemp -d)
cd "$(dirname "$0")/.."
xvfb-run -a -s "-screen 0 1280x720x24" "$GODOT" --rendering-driver opengl3 --resolution 1280x720 \
  --write-movie "$TMP/f.png" --fixed-fps $FPS --quit-after $((SECS * FPS)) -- --demo --cam="$CAM" "$@" \
  > "$TMP/log.txt" 2>&1 || true
grep -E "SCRIPT ERROR|Parse Error" "$TMP/log.txt" && exit 1
ffmpeg -loglevel error -y -framerate $FPS -i "$TMP/f%08d.png" -c:v libx264 -pix_fmt yuv420p -crf 26 "$OUT"
echo "frames: $(ls "$TMP" | grep -c png) -> $OUT"
rm -rf "$TMP"
