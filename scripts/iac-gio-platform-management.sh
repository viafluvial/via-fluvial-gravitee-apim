#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-}"
CONTEXT="${2:-remote}"
CLUSTER="${3:-management}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANSIBLE_DIR="$ROOT_DIR/ansible"

INVENTORY_FILE="${INVENTORY_FILE_OVERRIDE:-$ANSIBLE_DIR/config/inventory.ini}"
INVENTORY_LIMIT_RESOLVED="${INVENTORY_LIMIT:-$CLUSTER}"
ALLOW_UNINSTALL="${ALLOW_UNINSTALL:-false}"
ENVIRONMENT="${ENVIRONMENT:-prd}"

if [[ -z "${PORTAINER_ENV_FILE:-}" ]]; then
	if [[ -f "$ANSIBLE_DIR/config/portainer-${CLUSTER}-${ENVIRONMENT}.env" ]]; then
		PORTAINER_ENV_FILE="$ANSIBLE_DIR/config/portainer-${CLUSTER}-${ENVIRONMENT}.env"
	elif [[ -f "$ANSIBLE_DIR/config/portainer-${ENVIRONMENT}.env" ]]; then
		PORTAINER_ENV_FILE="$ANSIBLE_DIR/config/portainer-${ENVIRONMENT}.env"
	else
		PORTAINER_ENV_FILE="$ANSIBLE_DIR/config/portainer-management.env"
	fi
fi

if [[ -z "$ACTION" ]]; then
	echo "Uso: $0 <install|validate|uninstall> <remote|local> <management>" >&2
	exit 1
fi

if [[ ! -f "$INVENTORY_FILE" ]]; then
	echo "Inventário não encontrado: $INVENTORY_FILE" >&2
	exit 1
fi

if [[ "$ACTION" == "uninstall" && "$ALLOW_UNINSTALL" != "true" ]]; then
	echo "Desinstalação bloqueada. Use ALLOW_UNINSTALL=true." >&2
	exit 1
fi

if [[ -f "$PORTAINER_ENV_FILE" ]]; then
	set -a
	# shellcheck disable=SC1090
	source "$PORTAINER_ENV_FILE"
	set +a
else
	echo "[warn] Portainer env não encontrado: $PORTAINER_ENV_FILE" >&2
fi

export ANSIBLE_CONFIG="$ANSIBLE_DIR/config/ansible.cfg"

case "$ACTION" in
	install)
		ansible-playbook -i "$INVENTORY_FILE" "$ANSIBLE_DIR/playbooks/gio/playbook-21C-install-gio-management.yml" --limit "${INVENTORY_LIMIT_RESOLVED:-all}"
		;;
	validate)
		ansible-playbook -i "$INVENTORY_FILE" "$ANSIBLE_DIR/playbooks/gio/playbook-21V-validate-gio-management.yml" --limit "${INVENTORY_LIMIT_RESOLVED:-all}"
		;;
	uninstall)
		ansible-playbook -i "$INVENTORY_FILE" "$ANSIBLE_DIR/playbooks/gio/playbook-21D-uninstall-gio-management.yml" --limit "${INVENTORY_LIMIT_RESOLVED:-all}"
		;;
	*)
		echo "ACTION inválida: $ACTION" >&2
		exit 1
		;;
esac