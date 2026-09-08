#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

python3 "$script_dir/evaluation_order.py"
node "$script_dir/evaluation_order.js"
java "$script_dir/EvaluationOrder.java"
