# Aurora Agentic DBRE Lab

An independent DBRE.tech engineering field study investigating database-agent reliability on Amazon Aurora PostgreSQL.

**Status:** research in progress; repository initialization. The original Terraform and local experiment source are undergoing a source-provenance and security audit before publication. **Do not deploy from this repository yet.**

Inspired by AWS re:Invent DAT302; this is not an AWS publication or endorsed implementation.

## Research question

Can an AI database agent not only diagnose and change a database, but also demonstrate measurable recovery under a controlled workload?

## Experimental record (October 2026)

- Aurora discovery agent: demonstrated.
- SQL health diagnostics agent: demonstrated.
- Database action agent: reported concurrent index creation on `projects(proj_name)`; actual workload benefit remains unproven.
- Supervisor: final continuous-workload qualification pending.
- Persistent per-cluster operational memory: proposed, not implemented.

Our strongest initial finding is that successful tool execution alone is **not** proof of safe or useful remediation: an overlapping index was already present and the agent did not establish the incremental performance benefit.

## Source publication

The independent Terraform and workflow scripts are being audited for secrets, safe teardown, consistency, and source provenance. AWS-provided workshop code is not automatically redistributable; any necessary agent functionality will be implemented independently unless a suitable license applies.

## Companion field study

[Draft DBRE.tech website PR #11](https://github.com/nbanob/cloud-dbre-tech-site/pull/11).
