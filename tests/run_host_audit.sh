#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
bash "$ROOT/tests/static_audit.sh"
python3 "$ROOT/tests/test_libinit_semantics.py"
bash "$ROOT/tests/test_module_loader.sh"
echo 'HOST AUDIT: PASS'
