#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${1:-}"
STACK_NAME_FILTER="${2:-}"

if [[ -z "$ENV_FILE" ]]; then
  echo "Uso: $0 <portainer.env> [stack_name]" >&2
  exit 1
fi

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Arquivo não encontrado: $ENV_FILE" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
. "$ENV_FILE"
set +a

CURL_TLS_FLAGS=()
if [[ "${PORTAINER_VALIDATE_CERTS:-false}" != "true" ]]; then
  CURL_TLS_FLAGS+=("-k")
fi

if [[ -z "${PORTAINER_URL:-}" ]]; then
  echo "PORTAINER_URL deve estar definido em $ENV_FILE" >&2
  exit 1
fi

if [[ -z "${PORTAINER_API_KEY:-}" && ( -z "${PORTAINER_USERNAME:-}" || -z "${PORTAINER_PASSWORD:-}" ) ]]; then
  echo "Defina PORTAINER_API_KEY ou PORTAINER_USERNAME/PORTAINER_PASSWORD em $ENV_FILE" >&2
  exit 1
fi

BASE_URL="${PORTAINER_URL%/}"

auth_header=""
if [[ -n "${PORTAINER_API_KEY:-}" ]]; then
  auth_header="X-API-Key: ${PORTAINER_API_KEY}"
else
  jwt="$(curl -sS "${CURL_TLS_FLAGS[@]}" -X POST "$BASE_URL/api/auth" \
    -H 'Content-Type: application/json' \
    -d "{\"username\":\"${PORTAINER_USERNAME}\",\"password\":\"${PORTAINER_PASSWORD}\"}" \
    | python3 -c 'import sys, json; print(json.load(sys.stdin).get("jwt",""))')"
  if [[ -z "$jwt" ]]; then
    echo "Falha ao autenticar no Portainer (jwt vazio)." >&2
    exit 2
  fi
  auth_header="Authorization: Bearer ${jwt}"
fi

endpoints_json="$(curl -sS "${CURL_TLS_FLAGS[@]}" -H "$auth_header" "$BASE_URL/api/endpoints")"
endpoint_id="${PORTAINER_ENDPOINT_ID:-}"

print_endpoints() {
  echo "Endpoints disponíveis em $BASE_URL:" >&2
  echo "$endpoints_json" | python3 - <<'PY'
import json, sys
try:
    eps = json.load(sys.stdin)
except Exception:
    print("(falha ao parsear JSON de endpoints)")
    sys.exit(0)

for e in eps:
    _id = e.get("Id", "")
    name = e.get("Name", "")
    etype = e.get("Type", "")
    url = (e.get("URL", "") or e.get("PublicURL", ""))
    print(f"- Id={_id} Name={name} Type={etype} URL={url}")
PY
}

if [[ -z "${PORTAINER_ENDPOINT_ID:-}" && -z "${PORTAINER_ENDPOINT_NAME:-}" ]]; then
  echo "PORTAINER_ENDPOINT_ID ou PORTAINER_ENDPOINT_NAME não definido em $ENV_FILE." >&2
  print_endpoints
  echo "\nAjuste o arquivo com UM destes:" >&2
  echo "- PORTAINER_ENDPOINT_ID=<Id acima>" >&2
  echo "- PORTAINER_ENDPOINT_NAME=<Name acima>" >&2
  exit 3
fi

if [[ -z "$endpoint_id" && -n "${PORTAINER_ENDPOINT_NAME:-}" ]]; then
  endpoint_id="$(echo "$endpoints_json" | python3 -c 'import sys, json; eps=json.load(sys.stdin); name="'"${PORTAINER_ENDPOINT_NAME}"'"; print(next((str(e.get("Id")) for e in eps if e.get("Name")==name), ""))')"
fi

if [[ -z "$endpoint_id" ]]; then
  if [[ "$(echo "$endpoints_json" | python3 -c 'import sys, json; print(len(json.load(sys.stdin)))')" == "1" ]]; then
    endpoint_id="$(echo "$endpoints_json" | python3 -c 'import sys, json; print(json.load(sys.stdin)[0].get("Id",""))')"
  fi
fi

if [[ -z "$endpoint_id" ]]; then
  echo "Não foi possível resolver endpointId. Ajuste PORTAINER_ENDPOINT_ID ou PORTAINER_ENDPOINT_NAME." >&2
  print_endpoints
  exit 3
fi

stacks_json="$(curl -sS "${CURL_TLS_FLAGS[@]}" -H "$auth_header" "$BASE_URL/api/stacks?endpointId=$endpoint_id")"

if [[ -n "$STACK_NAME_FILTER" ]]; then
  found="$(echo "$stacks_json" | python3 -c 'import sys, json; stacks=json.load(sys.stdin); name="'"${STACK_NAME_FILTER}"'"; print("1" if any(s.get("Name")==name for s in stacks) else "0")')"
  if [[ "$found" != "1" ]]; then
    echo "OK: API acessível, mas stack '${STACK_NAME_FILTER}' não encontrada (endpointId=${endpoint_id})."
    exit 0
  fi
  echo "OK: API acessível e stack '${STACK_NAME_FILTER}' encontrada (endpointId=${endpoint_id})."
  exit 0
fi

echo "OK: API do Portainer acessível (endpointId=${endpoint_id})."
