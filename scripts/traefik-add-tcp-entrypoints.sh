#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/traefik-add-tcp-entrypoints.sh [--service <name>]

What it does:
  - Ensures Traefik Swarm service has TCP entrypoints for:
      mongo=27017, postgres=5432, postgres3=5433, redis=6379, registry=5000
  - Ensures the Traefik service publishes those ports (tcp)

Defaults:
  --service traefik_traefik

Notes:
  - This script updates the running Swarm service (docker service update).
  - If you later redeploy Traefik via docker stack deploy from a compose file,
    you should also persist these args/ports in that compose definition.
EOF
}

SERVICE="traefik_traefik"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --service)
      SERVICE="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown arg: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if ! command -v docker >/dev/null 2>&1; then
  echo "docker not found in PATH" >&2
  exit 1
fi
if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 not found in PATH" >&2
  exit 1
fi

if ! docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null | grep -q '^active$'; then
  echo "Docker Swarm is not active on this node." >&2
  exit 1
fi

if ! docker service inspect "$SERVICE" >/dev/null 2>&1; then
  echo "Service '$SERVICE' not found. If your stack name differs, pass --service." >&2
  exit 1
fi

desired_entrypoints=(
  "mongo:27017"
  "postgres:5432"
  "postgres3:5433"
  "redis:6379"
  "registry:5000"
)

# Read current args as a JSON array of strings
current_args_json="$(docker service inspect "$SERVICE" --format '{{json .Spec.TaskTemplate.ContainerSpec.Args}}')"

# Build updates (args-rm/args-add) in one docker service update
mapfile -t existing_entrypoint_args < <(
  ARGS_JSON="$current_args_json" python3 - <<'PY'
import json, os
args = json.loads(os.environ.get('ARGS_JSON', 'null')) or []
for a in args:
  if isinstance(a, str) and a.startswith('--entrypoints.') and '.address=:' in a:
    print(a)
PY
)

rm_flags=()
add_flags=()

for ep in "${desired_entrypoints[@]}"; do
  name="${ep%%:*}"
  port="${ep##*:}"
  desired_arg="--entrypoints.${name}.address=:${port}"

  found_exact=false
  found_other=""
  for a in "${existing_entrypoint_args[@]}"; do
    if [[ "$a" == "$desired_arg" ]]; then
      found_exact=true
      break
    fi
    if [[ "$a" == --entrypoints.${name}.address=* ]]; then
      found_other="$a"
    fi
  done

  if [[ "$found_exact" == true ]]; then
    echo "[ok] entrypoint '$name' already set: $desired_arg"
    continue
  fi

  if [[ -n "$found_other" ]]; then
    echo "[warn] entrypoint '$name' exists with different value: $found_other"
    echo "       will replace with: $desired_arg"
    rm_flags+=(--args-rm "$found_other")
  else
    echo "[add] entrypoint '$name': $desired_arg"
  fi

  add_flags+=(--args-add "$desired_arg")
done

# Ensure published ports exist
current_ports_json="$(docker service inspect "$SERVICE" --format '{{json .EndpointSpec.Ports}}')"

publish_add_flags=()
for ep in "${desired_entrypoints[@]}"; do
  port="${ep##*:}"
  already_published="$(
    PORTS_JSON="$current_ports_json" DESIRED="$port" python3 - <<'PY'
import json, os, sys
ports = json.loads(os.environ.get('PORTS_JSON', 'null')) or []
desired = int(os.environ.get('DESIRED', '-1'))
for p in ports:
  if int(p.get('PublishedPort', -1)) == desired and str(p.get('Protocol','tcp')) == 'tcp':
    print('yes')
    break
PY
  )"

  if [[ "$already_published" == "yes" ]]; then
    echo "[ok] tcp port $port already published"
    continue
  fi

  echo "[add] publish tcp port $port (published=$port,target=$port)"
  publish_add_flags+=(--publish-add "published=${port},target=${port},protocol=tcp")
done

if [[ ${#rm_flags[@]} -eq 0 && ${#add_flags[@]} -eq 0 && ${#publish_add_flags[@]} -eq 0 ]]; then
  echo "No changes required."
  exit 0
fi

echo "Applying docker service update to '$SERVICE'..."
docker service update "$SERVICE" \
  "${rm_flags[@]}" \
  "${add_flags[@]}" \
  "${publish_add_flags[@]}"

echo "Done. You can validate with:"
echo "  docker service inspect $SERVICE --format '{{json .Spec.TaskTemplate.ContainerSpec.Args}}' | python3 -m json.tool"
echo "  docker service inspect $SERVICE --format '{{json .Endpoint.Ports}}' | python3 -m json.tool"
