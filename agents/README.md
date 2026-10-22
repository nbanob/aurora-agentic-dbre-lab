# Independently written agents

`discovery.py` is an intentionally small read-only RDS discovery example for the reconstructed Aurora lab. It calls DescribeDBClusters through boto3; it does not use SQL or alter the database. It is not a copy of AWS-distributed DAT302 material. Health, Action and Supervisor agents are on the roadmap pending independent implementation and verified safety controls.
