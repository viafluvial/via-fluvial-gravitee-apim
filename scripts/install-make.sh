#!/usr/bin/env bash
set -euo pipefail

if command -v make >/dev/null 2>&1; then
  echo "make já instalado: $(make --version | head -n 1)"
  exit 0
fi

echo "Instalando make (requer sudo)..."
sudo apt-get update -y
sudo apt-get install -y make
