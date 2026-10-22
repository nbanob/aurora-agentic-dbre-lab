# Source audit: DAT302-inspired field study (October 2026)

**Review status:** private source archive inspected. This PR is not yet a runnable release.

A private WSL export contained 43 file paths including Terraform, locally developed scripts, and recovered AWS workshop content. We have deliberately excluded recovered files under `workshop/agent/`, `workshop/bootstrap/`, and `workshop/sql-original/` from the proposed public package, pending redistribution-license review.

## Findings

- Independently authored Terraform: 8 `.tf` files plus a provider lockfile; built for disposable Aurora PostgreSQL, IAM, VPC, SSM tunnel, CloudWatch, SNS and optional AgentCore support.
- Independently authored scripts: synthetic seed, pgbench workload, environment/tunnel setup and safety preflight.
- A heuristic text scan found no embedded AWS access keys, 12-digit account IDs, or PEM private key blocks. This is not a comprehensive security audit.
- The recovered workshop-distributed Python/SQL sources are intentionally not included. A new independent read-only Strands discovery agent is being prepared.
- Shell syntax and independent Python syntax passed offline checks on the candidate package.
- Terraform formatting/validation **from the public tree**, live AWS deployment, successful Supervisor experiment, and before/after remediation qualification remain **pending**.

## Publication contract

Only publish independently authored or properly licensed sources. Never commit `terraform.tfstate`, `.terraform/`, `*.tfvars` containing settings or secrets, local `.env`, raw AWS credentials, deployment buckets/archives, or customer data.

The field study makes bounded claims about three agent demonstrations; it does **not** claim verified database self-healing.
