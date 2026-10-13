#!/bin/bash
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
F=$(ls "$ROOT"/dataset/raw/*.csv | head -n 1)
head -n 5000 "$F" | python3 "$ROOT/src/processing/clean_mapper.py" | head -n 5
echo "--- counters (stderr) ---"
head -n 5000 "$F" | python3 "$ROOT/src/processing/clean_mapper.py" 2>&1 >/dev/null
