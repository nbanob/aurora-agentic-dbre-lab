# Engineering record — October 2026

## Environment

- AWS region: `us-west-2`.
- Aurora PostgreSQL 16.10, synthetic `hr_messy` database.
- Terraform-managed VPC, private/public subnets, Aurora writer/reader, SSM access, network components, IAM, CloudWatch logging and metrics, SNS, AgentCore-related supporting networking.
- A successful teardown reported **42 resources destroyed**. AgentCore runtimes, the previously used S3 deployment bucket, and manual cluster snapshots were checked separately and absent.
- These observations come from terminal output. The full repository source and fresh reproducibility test remain to be audited.

## Discovery experiment

Input: `List Aurora clusters in the current region`.

Sonnet 4.6, using Strands, selected the discovery tool and returned the expected Aurora cluster `apgpg-dat302`, database `hr_messy`, writer and reader endpoints, and engine version. This validates a narrow tool-selection and API-invocation path.

## Diagnostic experiment

Input: `Show me the top queries`.

The health agent selected its top-queries tool, queried `aurora_stat_plans`, and described historical SQL including data loading, index builds, and analyze. This did **not** demonstrate successful diagnosis of a running application's high-CPU problem; the recorded top queries mostly reflected the database initialization.

## Action experiment

Input: `Create an index on the projects table for the proj_name column`.

The action agent reported creating `idx_projects_proj_name` with `CREATE INDEX CONCURRENTLY` in roughly 4.3 seconds. The preflight index listing contained a composite B-tree index on `(proj_name, budget)`. The action tool reported success, but we have no comparable pre/post measurements demonstrating performance benefit.

## Known issues

1. The health agent depended on substantial hardcoded PostgreSQL catalog SQL.
2. The action agent did not automatically prevent potentially overlapping indexes.
3. The agent described concurrent index creation as "zero downtime" and guaranteed index scans; neither guarantee is justified.
4. Current inputs and outputs do not prove safe self-healing.
5. The final Supervisor benchmark did not complete in the captured session. Do not claim four validated exercises.

## Future experiment acceptance criteria

- Identical workload definition and comparable conditions for before/after.
- Time-series CPU, throughput, p50/p95 latency, query plans, error rates, and wait events where available.
- Before/after samples recorded while the load is running; reject stopping the workload as a false improvement signal.
- Explicit recorded action, approval, verification, rollback criteria, and confidence/uncertainty.
- An unsuccessful or harmful change is preserved as a negative result.
