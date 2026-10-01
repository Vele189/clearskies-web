#!/usr/bin/env bash
# Start the frontend locally, in a container.
#
#   ./start.sh          build and serve on http://localhost:8080 in the foreground
#   ./start.sh down     stop it
#
# Start the API first (clearskies-api-/start.sh). VITE_API_BASE_URL and the
# other VITE_ settings come from .env when one exists (see .env.example) and
# are baked in at build time, so a changed value takes effect on the next run
# of this script, which rebuilds.

set -euo pipefail

cd "$(dirname "$0")"

if [[ "${1:-}" == "down" ]]; then
  docker compose down
  exit 0
fi

api="${VITE_API_BASE_URL:-$(sed -n 's/^VITE_API_BASE_URL=//p' .env 2>/dev/null || true)}"
api="${api:-http://localhost:8000}"
if ! curl -fsS --max-time 3 "$api/health" >/dev/null 2>&1; then
  echo "warning: no API answering at $api/health; the map will load without data." >&2
fi

echo "==> Serving on http://localhost:${WEB_PORT:-8080}, API at $api"
trap 'docker compose stop' EXIT
docker compose up --build web
