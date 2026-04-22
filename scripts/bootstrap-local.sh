#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[bootstrap] Instalando dependências locais (make, sshpass, ansible)..."

bash "$ROOT_DIR/scripts/install-make.sh"
bash "$ROOT_DIR/scripts/install-sshpass.sh"
bash "$ROOT_DIR/scripts/install-ansible.sh"

echo "[bootstrap] Concluído."
