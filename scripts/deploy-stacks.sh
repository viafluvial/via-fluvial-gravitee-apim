#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Uso: $0 <repository|management|gateway|platform>" >&2
  exit 1
fi

TARGET="$1"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENVIRONMENT="${ENVIRONMENT:-prd}"
WITH_PREREQS="${WITH_PREREQS:-false}"

bash "$ROOT_DIR/scripts/iac.sh" install "$ENVIRONMENT" "$TARGET" "$WITH_PREREQS"

echo "Stacks instaladas com sucesso para ${TARGET} em ${ENVIRONMENT}."
