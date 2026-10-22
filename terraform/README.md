# Terraform: isolated Aurora PostgreSQL lab

This configuration was imported from our own DAT302 infrastructure reconstruction. It is **billable** and should only be applied in a disposable AWS sandbox. It manages networking, two private subnets, one optional-reader Aurora PG16 cluster, SSM tunnel host, NAT Gateway for optional AgentCore networking, IAM support roles, CloudWatch and SNS.

**It does not deploy AgentCore runtimes, agents, application workloads or source code.** An AgentCore runtime deployed separately will require separately managed teardown.

The default `lab_acknowledged=false` deliberately prevents an accidental `plan/apply` unless explicitly enabled through a local, gitignored `terraform.tfvars` file.

The RDS-managed master password is not stored as a Terraform resource argument. Nevertheless, **Terraform state remains sensitive** (resource metadata/ARNs etc.): never commit or publicly distribute state.

Lab caveats: NAT Gateway accrues hourly and processing charges. Cross-AZ routing is not HA. Database Insights advanced mode and retention may increase cost. Deletion protection is intentionally disabled and final snapshot skipped, therefore data is disposable. AgentCore IAM is broader than production least-privilege and requires tightening before reuse outside a sandbox.

See the repository README for deployment sequence and `docs/teardown.md` for independent-resource checks.
