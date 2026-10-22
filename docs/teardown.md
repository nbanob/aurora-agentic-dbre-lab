# Shutdown and cost verification

Always run destroy from the same state, variables, AWS profile, and workspace used at apply.

```bash
terraform -chdir=terraform destroy
```

Do not assume success until the command says `Destroy complete!`.

Afterward, check for **lab-specific resources** created outside Terraform; use scoped names and never delete unrelated resources:

```bash
aws bedrock-agentcore-control list-agent-runtimes --region us-west-2 --output table
aws s3api list-buckets --query 'Buckets[?contains(Name, `bedrock-agentcore-codebuild-sources-`)].Name' --output table
aws rds describe-db-cluster-snapshots --region us-west-2 --snapshot-type manual --query 'DBClusterSnapshots[?DBClusterIdentifier==`apgpg-dat302`].[DBClusterSnapshotIdentifier,Status]' --output table
aws rds describe-db-cluster-automated-backups --region us-west-2 --query 'DBClusterAutomatedBackups[?DBClusterIdentifier==`apgpg-dat302`].[DBClusterIdentifier,Status]' --output table
```

AWS charges for already consumed services may post later even after teardown. Also check retained S3 data, CloudWatch log groups, Secrets Manager secrets, EBS snapshots, elastic IPs and NAT Gateways **by the lab's names/tags** if created manually. AWS billing and Cost Explorer can help detect residual expense.
