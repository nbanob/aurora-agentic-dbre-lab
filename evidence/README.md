# Evidence policy

Do not commit raw secrets, customer data, AWS account identifiers, credentials or excessive service logs. All public evidence must be synthetic or anonymized and explain source, measurement window, workload, query definition, baseline, intervention, post-change measurements and interpretation.

## Proposed evidence artifacts

- `environment-inventory.json`: sanitized environment shape and database version.
- `run-manifest.json`: git commit, scenario, timestamps, parameters and AWS region.
- `baseline.csv` and `post-change.csv`: timestamped CPU, throughput, p95 latency, errors, wait events.
- `query-plans/`: sanitized EXPLAIN plans before and after.
- `decisions/`: approved/rejected remediation memo and safety check result.
- `summary.md`: what the evidence proves and does not prove.

These files are **planned**, not present in this starter.
