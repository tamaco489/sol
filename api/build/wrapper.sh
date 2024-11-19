#!/usr/bin/env bash

set -euo pipefail

MIGRATION_METHOD=${1:-"up"}

echo "Starting script with MIGRATION_METHOD set to '${MIGRATION_METHOD}'"

if [ "${ENV}" == "dev" ]; then
  secrets=$(aws secretsmanager get-secret-value --secret-id "sol/${ENV}/rds-cluster" --endpoint-url="http://localstack:4566" | jq -r .SecretString)
  CONFIG_FILE="dbconfig.yml"
  MIGRATION_ENV="mysql"
  echo "Environment set to development"
elif [ "${ENV}" == "test" ]; then
  secrets=$(aws secretsmanager get-secret-value --secret-id "sol/${ENV}/rds-cluster" --endpoint-url="http://localhost:4566" | jq -r .SecretString)
  CONFIG_FILE="./internal/db/dbconfig.yml"
  MIGRATION_ENV="test"
  echo "Environment set to test"
else
  secrets=$(aws secretsmanager get-secret-value --secret-id "sol/${ENV}/rds-cluster" | jq -r .SecretString)
  CONFIG_FILE="dbconfig.yml"
  MIGRATION_ENV="mysql"
  echo "Environment set to production or other non-dev/test environment"
fi

echo "Configuration File: ${CONFIG_FILE}"
echo "Migration Environment: ${MIGRATION_ENV}"

DB_NAME=$(echo "${secrets}" | jq -r .dbname)
DB_HOST=$(echo "${secrets}" | jq -r .host)
DB_USER=$(echo "${secrets}" | jq -r .username)
DB_PORT=$(echo "${secrets}" | jq -r .port)
DB_PASS=$(echo "${secrets}" | jq -r .password)

echo "Database configuration set - DB_NAME: ${DB_NAME}, DB_HOST: ${DB_HOST}, DB_USER: ${DB_USER}, DB_PORT: ${DB_PORT}"

export DB_NAME DB_HOST DB_USER DB_PORT DB_PASS CONFIG_FILE MIGRATION_METHOD MIGRATION_ENV

result=$(sql-migrate "${MIGRATION_METHOD}" -config="${CONFIG_FILE}" -env="${MIGRATION_ENV}")
echo "Migration result: ${result}"
