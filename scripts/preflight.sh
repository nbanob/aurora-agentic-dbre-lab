#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
for bin in aws terraform; do command -v "$bin" >/dev/null || { echo "Missing: $bin"; exit 1; }; done
region="$(terraform -chdir="$root/terraform" output -raw aws_region)"
cluster="$(terraform -chdir="$root/terraform" output -raw aurora_cluster_id)"
id="$(terraform -chdir="$root/terraform" output -raw ssm_instance_id)"
echo '=== Caller identity ==='
aws sts get-caller-identity --query '{Account:Account,Arn:Arn}' --output table
echo '=== Aurora cluster ==='
aws rds describe-db-clusters --region "$region" --db-cluster-identifier "$cluster" --query 'DBClusters[0].{Status:Status,Engine:Engine,Version:EngineVersion,Mode:DatabaseInsightsMode,Writer:Endpoint,Instances:DBClusterMembers[*].DBInstanceIdentifier}' --output json
echo '=== SSM managed instance (may take 2-5 min after apply) ==='
aws ssm describe-instance-information --region "$region" --filters "Key=InstanceIds,Values=$id" --query 'InstanceInformationList[*].{Id:InstanceId,Status:PingStatus}' --output json
echo '=== AWS RDS-managed secret metadata ==='
arn="$(terraform -chdir="$root/terraform" output -raw aurora_master_secret_arn)"
aws secretsmanager describe-secret --region "$region" --secret-id "$arn" --query '{Name:Name,ARN:ARN}' --output json
