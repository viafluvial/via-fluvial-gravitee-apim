#!/usr/bin/env bash
set -euo pipefail

if command -v sshpass >/dev/null 2>&1; then
  echo "sshpass já instalado: $(sshpass -V 2>&1 | head -n 1)"
  exit 0
fi

echo "Instalando sshpass (requer sudo)..."
sudo apt-get update -y
sudo apt-get install -y sshpass
