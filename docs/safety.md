# Safety boundaries

**Research prototype only. Not production approved.**

- Separate read-only telemetry credentials from privileged DDL execution identity.
- Treat LLM-generated reasoning as a hypothesis, not permission to execute SQL.
- Enforce statement-level policies, allowed schemas and operations, identity/identifier validation, query/lock timeouts, and independent change approval for DDL.
- `CREATE INDEX CONCURRENTLY` is lower locking impact, **not zero-risk**. It can wait on transactions and consume substantial resources; failed operations can leave invalid indexes.
- Avoid a blind `DROP INDEX` response to an unused or redundant-index finding; validate indexes, constraints, workload context, and dependencies.
- Benchmark using consistent active load, not CPU readings after the workload stops.
- Require verifiable acceptance criteria, plus change rollback or safe escalation if conditions worsen.
- Maintain deterministic audit logs of input evidence, proposed SQL, tool execution, approval, and observed result.
