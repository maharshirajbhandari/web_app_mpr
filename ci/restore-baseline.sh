#!/usr/bin/env sh
set -eu

compose_file="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/docker-compose.baseline.yml"
service="postgres"

docker compose -f "$compose_file" up -d "$service"

ready=0
i=0
while [ "$i" -lt 60 ]; do
  if docker compose -f "$compose_file" exec -T "$service" pg_isready -U postgres -d base_imis >/dev/null 2>&1; then
    ready=1
    break
  fi
  i=$((i + 1))
  sleep 2
done

if [ "$ready" -ne 1 ]; then
  echo "PostgreSQL did not become ready" >&2
  exit 1
fi

docker compose -f "$compose_file" exec -T "$service" \
  pg_restore \
  --username=postgres \
  --dbname=base_imis \
  --no-owner \
  --no-privileges \
  --exit-on-error \
  /baseline/base_imis.dump

docker compose -f "$compose_file" exec -T "$service" \
  psql --username=postgres --dbname=base_imis --set=ON_ERROR_STOP=1 \
  --command="SELECT extname, extversion FROM pg_extension WHERE extname IN ('postgis', 'postgis_topology', 'pgrouting') ORDER BY extname; SELECT count(*) AS user_tables FROM pg_catalog.pg_tables WHERE schemaname NOT IN ('pg_catalog', 'information_schema');"

echo "Baseline restored and verified. Laravel migrations were not run."
