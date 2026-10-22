"""Read-only Aurora cluster discovery using Strands and Amazon Bedrock.

Original educational implementation for DBRE.tech; not AWS DAT302 source.
Requires an AWS identity authorized to DescribeDBClusters and invoke a supported model.
"""
import os

import boto3
from strands import Agent, tool
from strands.models import BedrockModel


@tool
def list_aurora_clusters() -> list[dict]:
    """List Aurora database clusters and key non-secret properties in AWS_REGION."""
    client = boto3.client("rds", region_name=os.getenv("AWS_REGION", "us-west-2"))
    results = []
    paginator = client.get_paginator("describe_db_clusters")
    for page in paginator.paginate():
        for item in page.get("DBClusters", []):
            if not item.get("Engine", "").startswith("aurora-"):
                continue
            results.append({
                "identifier": item["DBClusterIdentifier"],
                "engine": item.get("Engine"),
                "engine_version": item.get("EngineVersion"),
                "status": item.get("Status"),
                "database": item.get("DatabaseName"),
                "members": [m.get("DBInstanceIdentifier") for m in item.get("DBClusterMembers", [])],
            })
    return results


def main() -> None:
    model_id = os.environ.get("BEDROCK_MODEL_ID")
    if not model_id:
        raise SystemExit("Export BEDROCK_MODEL_ID with a model accessible to your AWS account")
    model = BedrockModel(model_id=model_id, region_name=os.getenv("AWS_REGION", "us-west-2"))
    agent = Agent(
        model=model,
        system_prompt=(
            "You are a read-only Aurora inventory assistant. "
            "Use the provided discovery tool for cluster facts; do not invent resources. "
            "Never suggest a write action as already performed."
        ),
        tools=[list_aurora_clusters],
    )
    while True:
        try:
            question = input("\nQuestion (exit to quit): ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\nGoodbye")
            return
        if not question:
            continue
        if question.lower() in ("exit", "quit"):
            return
        try:
            agent(question)
        except Exception as exc:
            # Do not print the entire AWS request/exception chain to shared logs.
            print(f"Agent request failed: {type(exc).__name__}: {exc}")


if __name__ == "__main__":
    main()
