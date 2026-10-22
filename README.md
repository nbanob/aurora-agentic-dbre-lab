# Aurora Agentic DBRE Lab

An independent, evidence-driven field study of Amazon Aurora PostgreSQL, Terraform, and AI-assisted database reliability.

**Status: v0.1 research implementation.** The Terraform and shell-based synthetic workload were imported from an independently engineered local lab and screened for obvious embedded credentials. The independent Strands agent is an initial example, not production-ready. The final Supervisor experiment and controlled before/after performance qualification are **not yet complete**. This is not an AWS workshop redistribution.

Inspired by the AWS re:Invent DAT302 autonomous DBOps session, but not affiliated with or endorsed by AWS. The recovered AWS workshop agent and bootstrap files are deliberately **excluded** while redistribution permissions are reviewed. The independent Python agent here was written for this research repository.

## Research question

Can an AI database agent identify a real performance problem, select a safe intervention, and **demonstrate measurable recovery** rather than report only that an AWS API or SQL statement executed?

## What was actually demonstrated

| Stage | Evidence | Qualification |
| --- | --- | --- |
| Infrastructure | Terraform deployed and destroyed an isolated Aurora/SSM environment; terminal reported 42 destroyed resources | Existing WSL deployment, not yet revalidated from this published tree |
| Discovery agent | Sonnet 4.6 selected a tool and described the Aurora cluster | Functional workshop demonstration |
| Health agent | Returned Aurora top SQL statistics, dominated by seed operations | Functional workshop demonstration; not a sustained-load diagnosis |
| Action agent | Reported a concurrent index build on `projects(proj_name)` | Index already overlapped with `(proj_name,budget)`; impact unverified |
| Supervisor | Unqualified final experiment | Pending |
| Memory/self-healing | Not implemented | Research goal |

## Architecture and publication boundaries

The `terraform/` directory provisions a **billable**, disposable Aurora PostgreSQL lab, VPC, SSM tunneling host, NAT egress for optional AgentCore connectivity, IAM roles, SNS, CloudWatch, and Database Insights. **Terraform does not deploy AgentCore runtime or the Strands agent.** Optional supporting IAM/egress resources are provisioned even when AgentCore runtime is not deployed. NAT Gateway and public IPv4 allocations incur charges until destroyed. Terraform state must remain private.

The `scripts/` directory contains the independent synthetic seed, pgbench scenario and session setup. The `agents/` directory contains a deliberately small read-only RDS discovery example, not the original DAT302 distributed agent source.

## Prerequisites

- AWS account with permission to provision Aurora/RDS, VPC, EC2, SSM, Secrets Manager, CloudWatch, IAM, and SNS.
- AWS CLI v2 authenticated in WSL2 or Linux; Terraform >= 1.6 using AWS provider ~> 6.0.
- PostgreSQL `psql` and `pgbench`, Python 3.11+, and the AWS Session Manager plugin.
- Bedrock model-access entitlement **for the model you select**. An accepted model agreement alone does not guarantee inference access.
- A sandbox account and budget alerts; this lab has no production safeguards.

## Deploy only after reviewing AWS charges

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Open terraform/terraform.tfvars and consciously set lab_acknowledged = true
terraform -chdir=terraform init
terraform -chdir=terraform fmt -check
terraform -chdir=terraform validate
terraform -chdir=terraform plan
terraform -chdir=terraform apply
```

Wait until the SSM instance is online, then in **terminal A**:

```bash
bash scripts/start_tunnel.sh
```

In **terminal B**:

```bash
source scripts/load_env.sh
bash scripts/preflight.sh
export DAT302_CONFIRM_DESTRUCTIVE=yes   # ONLY on the newly deployed disposable hr_messy DB
bash scripts/seed.sh
unset DAT302_CONFIRM_DESTRUCTIVE
DAT302_BENCH_CLIENTS=4 DAT302_BENCH_SECONDS=180 bash scripts/benchmark.sh
```

### Independent RDS discovery agent

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
export AWS_REGION=us-west-2
export BEDROCK_MODEL_ID='us.anthropic.claude-sonnet-4-6' # example; validate your actual access
python agents/discovery.py
```

This agent is **read-only** and does not connect to PostgreSQL or modify the database. The legacy workshop Health, Action, and Supervisor agents are intentionally not included.

## Tear down on the same day

```bash
terraform -chdir=terraform destroy
```

Verify `Destroy complete!`. Then check for anything separately created outside Terraform, including AgentCore runtimes, deployment S3 buckets, CloudWatch logs, and retained RDS snapshots/backups. Stop the local SSM tunnel. See [docs/teardown.md](docs/teardown.md).

## Five-minute reviewer path

1. Read [engineering record](docs/engineering-record.md) and [source audit](docs/source-audit.md).
2. Inspect [Terraform infrastructure](terraform/) and [synthetic benchmark](scripts/).
3. Review [safety boundaries](docs/safety.md) and [research roadmap](docs/roadmap.md).
4. Compare the published evidence against the measured outcomes, **not** the agent's own claims.

## Companion field study

[DBRE.tech draft pull request #11](https://github.com/nbanob/cloud-dbre-tech-site/pull/11).
