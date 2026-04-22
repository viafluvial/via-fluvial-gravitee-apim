#!/usr/bin/env bash
set -euo pipefail

if command -v ansible-playbook >/dev/null 2>&1; then
  echo "ansible já instalado: $(ansible-playbook --version | head -n 1)"
  exit 0
fi

echo "Instalando ansible (requer sudo)..."
sudo apt-get update -y
sudo apt-get install -y ansible
