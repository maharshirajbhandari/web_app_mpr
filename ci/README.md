# Local CI database

The current approved database is treated as the baseline. This CI setup does not run Laravel migrations.

The Ansible deployment uses `postgis/postgis:<major>-3.5-alpine`, but the baseline requires `pgrouting`. CI therefore uses:

```text
pgrouting/pgrouting:14-3.5-3.8.0
```

This is a CI-only choice. It does not change Ansible or the production deployment.

From the workspace root, start the temporary database with:

```bash
docker compose -f web_app_mpr/ci/docker-compose.baseline.yml up -d postgres
```

The restore and verification script will:

1. wait for PostgreSQL;
2. restore `base_imis.sql` with `pg_restore`;
3. verify PostGIS, PostGIS topology, and pgRouting;
4. verify the expected baseline schema;
5. run no Laravel migrations.

The image tag must remain pinned. If the PostgreSQL major version changes in Ansible, the CI image must be updated deliberately.
