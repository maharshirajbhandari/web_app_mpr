#!/usr/bin/env bash
set -eu

pg_restore \
  --username=postgres \
  --dbname=base_imis \
  --no-owner \
  --no-privileges \
  --exit-on-error \
  /baseline/base_imis.dump

echo 'Baseline restored for application image tests. Laravel migrations were not run.'
