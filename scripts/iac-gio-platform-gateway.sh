#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-}"
CONTEXT="${2:-remote}"
CLUSTER="${3:-gateway}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANSIBLE_DIR="$ROOT_DIR/ansible"
ENVIRONMENT="${ENVIRONMENT:-prd}"

if [[ -n "${INVENTORY_FILE_OVERRIDE:-}" ]]; then
	INVENTORY_FILE="$INVENTORY_FILE_OVERRIDE"
elif [[ -f "$ROOT_DIR/gcp/config/inventory/${ENVIRONMENT}.ini" ]]; then
	INVENTORY_FILE="$ROOT_DIR/gcp/config/inventory/${ENVIRONMENT}.ini"
else
	INVENTORY_FILE="$ANSIBLE_DIR/config/inventory/${ENVIRONMENT}.ini"
fi

INVENTORY_LIMIT_RESOLVED="${INVENTORY_LIMIT:-$CLUSTER}"
ALLOW_UNINSTALL="${ALLOW_UNINSTALL:-false}"

if [[ -z "${PORTAINER_ENV_FILE:-}" ]]; then
	if [[ -f "$ROOT_DIR/gcp/config/portainer-${CLUSTER}.env" ]]; then
		PORTAINER_ENV_FILE="$ROOT_DIR/gcp/config/portainer-${CLUSTER}.env"
	elif [[ -f "$ROOT_DIR/gcp/config/portainer-${CLUSTER}-${ENVIRONMENT}.env" ]]; then
		PORTAINER_ENV_FILE="$ROOT_DIR/gcp/config/portainer-${CLUSTER}-${ENVIRONMENT}.env"
	elif [[ -f "$ANSIBLE_DIR/config/portainer-${CLUSTER}-${ENVIRONMENT}.env" ]]; then
		PORTAINER_ENV_FILE="$ANSIBLE_DIR/config/portainer-${CLUSTER}-${ENVIRONMENT}.env"
	elif [[ -f "$ANSIBLE_DIR/config/portainer-${CLUSTER}.env" ]]; then
		PORTAINER_ENV_FILE="$ANSIBLE_DIR/config/portainer-${CLUSTER}.env"
	elif [[ -f "$ANSIBLE_DIR/config/portainer-${ENVIRONMENT}.env" ]]; then
		PORTAINER_ENV_FILE="$ANSIBLE_DIR/config/portainer-${ENVIRONMENT}.env"
	else
		PORTAINER_ENV_FILE="$ROOT_DIR/gcp/config/portainer-gateway.env"
	fi
fi

if [[ -z "$ACTION" ]]; then
	echo "Uso: $0 <install|validate|uninstall> <remote|local> <gateway>" >&2
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
export PORTAINER_EXPECTED_ENDPOINT_NAME="${PORTAINER_EXPECTED_ENDPOINT_NAME:-$CLUSTER}"

case "$ACTION" in
	install)
		ansible-playbook -i "$INVENTORY_FILE" "$ANSIBLE_DIR/playbooks/gio/playbook-install-gio-gateway.yml" --limit "${INVENTORY_LIMIT_RESOLVED:-all}"
		;;
	validate)
		ansible-playbook -i "$INVENTORY_FILE" "$ANSIBLE_DIR/playbooks/gio/playbook-validate-gio-gateway.yml" --limit "${INVENTORY_LIMIT_RESOLVED:-all}"
		;;
	uninstall)
		ansible-playbook -i "$INVENTORY_FILE" "$ANSIBLE_DIR/playbooks/gio/playbook-uninstall-gio-gateway.yml" --limit "${INVENTORY_LIMIT_RESOLVED:-all}"
		;;
	*)
		echo "ACTION inválida: $ACTION" >&2
		exit 1
		;;
esac