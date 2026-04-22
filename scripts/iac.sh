#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-install}"
ENVIRONMENT="${2:-prd}"
TARGET="${3:-platform}"
WITH_PREREQS="${4:-false}"

INVENTORY_LIMIT="${INVENTORY_LIMIT:-}"
INVENTORY_FILE_OVERRIDE="${INVENTORY_FILE_OVERRIDE:-}"
ALLOW_DSV_CHANGES="${ALLOW_DSV_CHANGES:-false}"
TASK_HISTORY_LIMIT="${TASK_HISTORY_LIMIT:-1}"
CLEAN_STACKS="${CLEAN_STACKS:-}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANSIBLE_DIR="$ROOT_DIR/ansible"

usage() {
	cat <<USAGE
Uso:
	scripts/iac.sh <install|uninstall|check|clean|clean-hard> [dsv|hml|prd] [repository|management|gateway|platform] [true|false]

Exemplos:
	ENVIRONMENT=prd scripts/iac.sh install prd platform
	ENVIRONMENT=prd scripts/iac.sh check prd gateway
	TASK_HISTORY_LIMIT=1 scripts/iac.sh clean prd platform
	ALLOW_UNINSTALL=true scripts/iac.sh clean-hard prd platform

Variáveis opcionais:
	INVENTORY_LIMIT=<grupo_ou_host>          (sobrescreve --limit)
	INVENTORY_FILE_OVERRIDE=<arquivo.ini>    (sobrescreve inventário)
	ALLOW_DSV_CHANGES=true                   (libera alterações em dsv)
	TASK_HISTORY_LIMIT=<n>                   (default: 1)
	CLEAN_STACKS=<csv>                       (sobrescreve stacks para clean)
USAGE
}

require_tools() {
	command -v ansible-playbook >/dev/null 2>&1 || {
		echo "ansible-playbook não encontrado. Execute: make setup-local" >&2
		exit 1
	}
}

resolve_inventory_file() {
	local env="$1"
	local inventory=""

	case "$env" in
		dsv) inventory="$ANSIBLE_DIR/config/inventory/dsv.ini" ;;
		hml) inventory="$ANSIBLE_DIR/config/inventory/hml.ini" ;;
		prd) inventory="$ANSIBLE_DIR/config/inventory/prd.ini" ;;
		*)
			echo "Ambiente '$env' não suportado. Use dsv, hml ou prd." >&2
			exit 1
			;;
	esac

	if [[ -n "$INVENTORY_FILE_OVERRIDE" ]]; then
		inventory="$INVENTORY_FILE_OVERRIDE"
	fi

	# fallback de compatibilidade
	if [[ ! -f "$inventory" ]]; then
		inventory="$ANSIBLE_DIR/config/inventory.ini"
	fi

	if [[ ! -f "$inventory" ]]; then
		echo "Arquivo de inventário não encontrado: $inventory" >&2
		exit 1
	fi

	echo "$inventory"
}

guard_environment_safety() {
	if [[ "$ENVIRONMENT" == "dsv" && ( "$ACTION" == "install" || "$ACTION" == "uninstall" || "$ACTION" == "clean" || "$ACTION" == "clean-hard" ) && "$ALLOW_DSV_CHANGES" != "true" ]]; then
		echo "[iac] Bloqueado por segurança: alterações em dsv exigem ALLOW_DSV_CHANGES=true." >&2
		exit 1
	fi
}

resolve_limit_group_for_target() {
	local env="$1"
	local target="$2"
	local limit=""

	if [[ -n "$INVENTORY_LIMIT" ]]; then
		echo "$INVENTORY_LIMIT"
		return
	fi

	case "$env" in
		dsv) limit="dsv" ;;
		hml) limit="hml" ;;
		prd)
			case "$target" in
				repository|management|gateway) limit="$target" ;;
				platform) limit="" ;; # plataforma usa limites por etapa
				*)
					echo "TARGET '$target' não suportado. Use repository, management, gateway ou platform." >&2
					exit 1
					;;
			esac
			;;
	esac

	echo "$limit"
}

make_with_inventory() {
	local make_target="$1"
	local inventory_file="$2"
	local inventory_limit="$3"

	(
		cd "$ROOT_DIR"
		ENVIRONMENT="$ENVIRONMENT" \
		INVENTORY_FILE_OVERRIDE="$inventory_file" \
		INVENTORY_LIMIT="$inventory_limit" \
		$(command -v make) "$make_target" CONTEXT=remote
	)
}

run_syntax_check() {
	local inventory_file="$1"
	local limit_group="$2"

	local pb_dir="$ANSIBLE_DIR/playbooks/gio"
	if [[ ! -d "$pb_dir" ]]; then
		echo "Diretório de playbooks não encontrado: $pb_dir" >&2
		exit 1
	fi

	# Valida apenas os playbooks efetivamente usados pelo fluxo "stacks" (v2)
	# para evitar falhas com playbooks legados que dependem de vault.
	for pb in "$pb_dir"/playbook-2*.yml "$pb_dir"/playbook-90*.yml; do
		[[ -f "$pb" ]] || continue
		ANSIBLE_CONFIG="$ANSIBLE_DIR/config/ansible.cfg" ansible-playbook \
			--syntax-check \
			-i "$inventory_file" \
			"$pb" \
			--limit "${limit_group:-all}" >/dev/null
	done

	echo "[iac] ansible-playbook --syntax-check: OK"
}

resolve_clean_stacks_csv() {
	if [[ -n "$CLEAN_STACKS" ]]; then
		echo "$CLEAN_STACKS"
		return
	fi

	case "$TARGET" in
		repository) echo "gio_mongo,gio_elasticsearch,gio_kibana,gio_mongo_express" ;;
		management) echo "gio_management" ;;
		gateway) echo "gio_gateway" ;;
		platform) echo "gio_mongo,gio_elasticsearch,gio_kibana,gio_mongo_express,gio_management,gio_gateway" ;;
		*) echo "gio_management,gio_gateway" ;;
	esac
}

run_clean() {
	local inventory_file="$1"
	local limit_group="$2"

	if ! [[ "$TASK_HISTORY_LIMIT" =~ ^[0-9]+$ ]]; then
		echo "TASK_HISTORY_LIMIT deve ser numérico. Valor atual: $TASK_HISTORY_LIMIT" >&2
		exit 1
	fi

	local stacks_csv
	stacks_csv="$(resolve_clean_stacks_csv)"

	ANSIBLE_CONFIG="$ANSIBLE_DIR/config/ansible.cfg" ansible-playbook \
		-i "$inventory_file" \
		"$ANSIBLE_DIR/playbooks/gio/playbook-90C-clean-services.yml" \
		--limit "${limit_group:-all}" \
		-e "task_history_limit=$TASK_HISTORY_LIMIT" \
		-e "clean_stacks_csv=$stacks_csv"
}

run_clean_hard() {
	if [[ "${ALLOW_UNINSTALL:-false}" != "true" ]]; then
		echo "[iac] clean-hard requer ALLOW_UNINSTALL=true" >&2
		exit 1
	fi

	echo "[iac] Executando clean-hard: uninstall -> install"
	"$ROOT_DIR/scripts/iac.sh" uninstall "$ENVIRONMENT" "$TARGET" "$WITH_PREREQS"
	"$ROOT_DIR/scripts/iac.sh" install "$ENVIRONMENT" "$TARGET" "$WITH_PREREQS"
}

if [[ "$WITH_PREREQS" == "true" ]]; then
	bash "$ROOT_DIR/scripts/bootstrap-local.sh"
fi

if [[ "$ACTION" == "-h" || "$ACTION" == "--help" ]]; then
	usage
	exit 0
fi

require_tools
guard_environment_safety

inventory_file="$(resolve_inventory_file "$ENVIRONMENT")"
limit_group="$(resolve_limit_group_for_target "$ENVIRONMENT" "$TARGET")"

echo "[iac] Ambiente: $ENVIRONMENT"
echo "[iac] Target: $TARGET"
echo "[iac] Inventory file: $inventory_file"
if [[ -n "${limit_group:-}" ]]; then
	echo "[iac] Limit/Grupo: $limit_group"
fi

case "$ACTION" in
	check)
		run_syntax_check "$inventory_file" "$limit_group"
		;;
	clean)
		run_clean "$inventory_file" "$limit_group"
		;;
	clean-hard)
		run_clean_hard
		;;
	install|uninstall)
		if [[ "$TARGET" == "platform" ]]; then
			# Ordem: repository -> management -> gateway
			if [[ "$ACTION" == "install" ]]; then
				make_with_inventory install-repository "$inventory_file" "$(resolve_limit_group_for_target "$ENVIRONMENT" repository)"
				make_with_inventory validate-repository "$inventory_file" "$(resolve_limit_group_for_target "$ENVIRONMENT" repository)"
				make_with_inventory install-management "$inventory_file" "$(resolve_limit_group_for_target "$ENVIRONMENT" management)"
				make_with_inventory validate-management "$inventory_file" "$(resolve_limit_group_for_target "$ENVIRONMENT" management)"
				make_with_inventory install-gateway "$inventory_file" "$(resolve_limit_group_for_target "$ENVIRONMENT" gateway)"
				make_with_inventory validate-gateway "$inventory_file" "$(resolve_limit_group_for_target "$ENVIRONMENT" gateway)"
			else
				make_with_inventory uninstall-gateway "$inventory_file" "$(resolve_limit_group_for_target "$ENVIRONMENT" gateway)"
				make_with_inventory uninstall-management "$inventory_file" "$(resolve_limit_group_for_target "$ENVIRONMENT" management)"
				make_with_inventory uninstall-repository "$inventory_file" "$(resolve_limit_group_for_target "$ENVIRONMENT" repository)"
			fi
		else
			case "$TARGET" in
				repository)
					make_with_inventory "${ACTION}-repository" "$inventory_file" "$limit_group"
					;;
				management)
					make_with_inventory "${ACTION}-management" "$inventory_file" "$limit_group"
					;;
				gateway)
					make_with_inventory "${ACTION}-gateway" "$inventory_file" "$limit_group"
					;;
				*)
					echo "TARGET '$TARGET' não suportado." >&2
					exit 1
					;;
			esac
		fi
		;;
	*)
		echo "Ação '$ACTION' não suportada." >&2
		usage >&2
		exit 1
		;;
esac
