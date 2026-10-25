#!/bin/bash
# Runs every gameplay check headless. Usage: GODOT=path tools/run_tests.sh
GODOT=${GODOT:-godot}
cd "$(dirname "$0")/.."
fail=0
PREFIX=""; MODE="--headless"
run() { out=$(timeout 90 $PREFIX "$GODOT" $MODE -- "$@" 2>&1 | grep -E "^(SCENARIO|TEST_RESULT|TEST_REPORT)|SCRIPT ERROR"); echo "$out"; echo "$out" | grep -q -E "PASS$|TEST_RESULT PASS" || fail=1; }
for sp in 430 720; do
  for k in crate wall tank ac rug cable gap; do
    for a in none act; do run --scenario=$k:$a --speed=$sp; done
  done
done
# Touch input needs a real display server: use a virtual one.
PREFIX="xvfb-run -a"; MODE="--rendering-driver opengl3"; run --scenario=touch; PREFIX=""; MODE="--headless"
run --test=30
[ $fail = 0 ] && echo "ALL TESTS PASS" || { echo "SOME TESTS FAILED"; exit 1; }
