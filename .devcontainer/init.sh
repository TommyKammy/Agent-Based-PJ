#!/bin/bash
# Dev Container initialization script
# This script runs when the container is first created/started

set -e

echo "=========================================="
echo "Dev Container Initialization"
echo "=========================================="

# 既にDockerfileでインストール済みなので、バージョン確認のみ行う
if command -v opencode &> /dev/null; then
    echo "✓ opencode is pre-installed in this image"
    echo "  Version: $(opencode --version)"
else
    echo "⚠ opencode command not found. Please check Dockerfile build logs."
    # 万が一のフォールバック（通常は実行されません）
    echo "Attempting fallback installation..."
    npm install -g opencode-ai oh-my-opencode
fi

echo "✓ Environment setup complete"
echo ""
echo "Available commands:"
echo "  oc              - opencode"
echo "  ocs             - opencode with sisyphus agent"
echo "  ocb             - opencode with build agent"
echo "  oce             - opencode with explore agent"
echo "  ocg             - opencode with general agent"
echo "  oco             - opencode with oracle agent"
echo ""
echo "Run 'oc-help' for more information"
echo "=========================================="
