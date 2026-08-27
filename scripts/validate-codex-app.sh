#!/usr/bin/env bash
set -euo pipefail

: "${CODEX_HOME:?Set CODEX_HOME}"
: "${CODEX:?Set CODEX executable}"

echo "=== BASE ==="
"$CODEX" mcp get codex_app

echo
echo "=== DOTTED LEAF MERGE ==="
"$CODEX" -c 'mcp_servers.codex_app.enabled_tools=["automation_update"]' mcp get codex_app

echo
echo "=== LIST ==="
"$CODEX" mcp list
