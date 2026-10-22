#!/usr/bin/env python3
"""Emit safely quoted shell exports of only username/password; consumer evals in shell memory."""
import json
import shlex
import subprocess
import sys

if len(sys.argv) != 3:
    raise SystemExit('Usage: secret_exports.py SECRET_ARN REGION')
arn, region = sys.argv[1:]
response = subprocess.check_output([
    'aws', 'secretsmanager', 'get-secret-value', '--secret-id', arn,
    '--region', region, '--output', 'json'
], text=True)
secret = json.loads(json.loads(response)['SecretString'])
assert isinstance(secret.get('username'), str) and isinstance(secret.get('password'), str), 'RDS secret missing username/password'
for k, v in [('PGUSER', secret['username']), ('PGPASSWORD', secret['password'])]:
    print(f'export {k}={shlex.quote(v)}')
