#!/bin/bash
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PY=$(command -v python3 || command -v python || true)
if [ -z "$PY" ]; then echo "No python3 found on this machine"; exit 1; fi
if ! "$PY" -c "import matplotlib" 2>/dev/null; then
  echo "matplotlib not found: creating a local virtualenv .venv-charts (gitignored)"
  "$PY" -m venv "$ROOT/.venv-charts"
  if [ -x "$ROOT/.venv-charts/bin/python" ]; then VPY="$ROOT/.venv-charts/bin/python"; else VPY="$ROOT/.venv-charts/Scripts/python.exe"; fi
  "$VPY" -m pip install --quiet matplotlib
  PY="$VPY"
fi
"$PY" "$ROOT/src/analytics/make_charts.py"
