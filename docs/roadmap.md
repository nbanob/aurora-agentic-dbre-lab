# Roadmap

## v0.1 — Reproducible independent baseline (partial; live qualification pending)

- Imported and screened user-authored Terraform, networking, Secrets Manager and SSM session setup, and scripts; live redeploy/validate still pending.
- Started an independently authored Strands discovery agent. Health/action/supervisor reimplementations are pending.
- Document requirements and all expected AWS service costs.
- Verify deploy, initialize sample data, run scenario, and destroy cleanly.
- Finish Supervisor benchmark under sustained load; record evidence and negative findings.
- Publish a reproducible repo and link it from the DBRE.tech field study.

## v0.2 — Controlled actions and evidence qualification

- Catalog duplicate/overlapping index detection and safe identifier handling.
- Approval gates, minimal IAM/DB privileges, timeouts, auditable tool results.
- Repeatable before/after CPU, latency, TPS and execution plan evidence.
- Structured incident report and verified-outcome decision memo.

## v0.3 — Context-specific intelligence

- Agent-driven read-only catalog exploration using trusted capability constraints.
- Persistent time-series baselines and per-cluster incident memory.
- Hypothesis tracking and outcome-based knowledge updates.
- Cross-cluster retrieval with environment similarity checks.

## Next field study

Compare AWS DevOps Agent investigation/learning against the custom Aurora DBRE implementation on equivalent incidents. Keep this as a separate repo and website study.
