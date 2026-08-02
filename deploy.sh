#!/usr/bin/env bash
set -euo pipefail

REMOTE_HOST="${REMOTE_HOST:-tinkertanker@dev.tk.sg}"
REMOTE_PATH="${REMOTE_PATH:-/home/tinkertanker-server/Docker/tinkertanker-logos}"
REPO_URL="${REPO_URL:-git@github.com:tinkertanker/tinkertanker-logos.git}"
REF="${REF:-main}"
SSH_OPTS="${SSH_OPTS:--o BatchMode=yes -o IdentityAgent=none -o IdentitiesOnly=yes}"

ssh ${SSH_OPTS} "${REMOTE_HOST}" "mkdir -p \"$(dirname "${REMOTE_PATH}")\""

ssh ${SSH_OPTS} "${REMOTE_HOST}" "
  set -euo pipefail

  if [ ! -d \"${REMOTE_PATH}/.git\" ]; then
    rm -rf \"${REMOTE_PATH}\"
    git clone \"${REPO_URL}\" \"${REMOTE_PATH}\"
  fi

  cd \"${REMOTE_PATH}\"
  git fetch --prune origin
  git checkout --detach \"${REF}\"

  docker compose up -d --build --remove-orphans
  docker compose ps

  container_id=\"\$(docker compose ps -q logos)\"
  if [ -z \"\${container_id}\" ]; then
    echo 'Logos container was not created.' >&2
    exit 1
  fi

  for attempt in 1 2 3 4 5 6; do
    health=\"\$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' \"\${container_id}\")\"
    [ \"\${health}\" = 'healthy' ] && break
    if [ \"\${health}\" = 'unhealthy' ] || [ \"\${health}\" = 'exited' ]; then
      docker compose logs --tail=100 logos
      exit 1
    fi
    sleep 2
  done

  health=\"\$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' \"\${container_id}\")\"
  if [ \"\${health}\" != 'healthy' ]; then
    echo \"Logos container did not become healthy (status: \${health}).\" >&2
    docker compose logs --tail=100 logos
    exit 1
  fi
"

curl --fail --silent --show-error --retry 5 --retry-delay 2 https://logos.tk.sg/healthz
echo "Deployed ${REF} to https://logos.tk.sg"

