#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
tf="$root/terraform"
for bin in aws terraform; do command -v "$bin" >/dev/null || { echo "$bin is required" >&2; exit 1; }; done
id="$(terraform -chdir="$tf" output -raw ssm_instance_id)"
host="$(terraform -chdir="$tf" output -raw aurora_writer_endpoint)"
region="$(terraform -chdir="$tf" output -raw aws_region)"
port="${DAT302_DB_PORT:-15432}"
# Does not expose port 5432 publicly; SSM proxies through managed EC2 instance.
params="$(python3 - "$host" "$port" <<'PY'
import json,sys
print(json.dumps({'host':[sys.argv[1]],'portNumber':['5432'],'localPortNumber':[sys.argv[2]]}))
PY
)"
echo "Starting SSM port-forward session -> Aurora private writer endpoint."
echo "Leave this terminal open. In a SECOND WSL terminal run: source scripts/load_env.sh"
exec aws ssm start-session --target "$id" --document-name AWS-StartPortForwardingSessionToRemoteHost --parameters "$params" --region "$region"
