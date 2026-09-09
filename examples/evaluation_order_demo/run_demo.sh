#!/usr/bin/env bash
set -euo pipefail

evaluation_demo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "error: required compiler or interpreter '$1' was not found in PATH" >&2
        exit 1
    fi
}

require_command python3
require_command node
require_command java
require_command cjc

cangjie_build_dir="$(mktemp -d)"
trap 'rm -rf -- "$cangjie_build_dir"' EXIT

python3 "$evaluation_demo_dir/evaluation_order.py"
node "$evaluation_demo_dir/evaluation_order.js"
java "$evaluation_demo_dir/EvaluationOrder.java"

cjc "$evaluation_demo_dir/evaluation_order.cj" -o "$cangjie_build_dir/evaluation_order"
"$cangjie_build_dir/evaluation_order"
