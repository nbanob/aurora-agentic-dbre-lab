#!/usr/bin/env bash
# Source this in the WSL terminal where you will run psql or the agents:
#   source scripts/load_env.sh
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "ERROR: Source this file: source scripts/load_env.sh" >&2
  exit 2
fi
_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
_tf="$_root/terraform"
command -v terraform >/dev/null || { echo "terraform not installed" >&2; return 1; }
command -v aws >/dev/null || { echo "AWS CLI not installed" >&2; return 1; }
export AWS_REGION="$(terraform -chdir="$_tf" output -raw aws_region)" || return 1
export AWS_DEFAULT_REGION="$AWS_REGION"
export DAT302_SECRET_ARN="$(terraform -chdir="$_tf" output -raw aurora_master_secret_arn)" || return 1
export DAT302_DB_NAME="$(terraform -chdir="$_tf" output -raw database_name)" || return 1
export SNS_TOPIC_ARN="$(terraform -chdir="$_tf" output -raw agentcore_notifications_topic_arn)" || return 1
export DAT302_DB_HOST=127.0.0.1
export DAT302_DB_PORT="${DAT302_DB_PORT:-15432}"
export PGHOST="$DAT302_DB_HOST"
export PGPORT="$DAT302_DB_PORT"
export PGDATABASE="$DAT302_DB_NAME"
# Obtain password and username in-memory, not through Terraform state or a .env file.
# No password is printed; only exported into your current shell.
_dat302_exports="$(python3 "$_root/scripts/secret_exports.py" "$DAT302_SECRET_ARN" "$AWS_REGION")" || return 1
eval "$_dat302_exports"
unset _dat302_exports _root _tf
printf 'DAT302 environment loaded: region=%s database=%s localhost port=%s (secret not displayed)\n' "$AWS_REGION" "$PGDATABASE" "$PGPORT"
