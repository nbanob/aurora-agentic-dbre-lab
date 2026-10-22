# DAT302 AWS re:Invent workshop - IAM additions only.
# Place in the existing DAT302-Terraform/terraform/ directory.
# Managed by the existing AWS provider and Terraform state.
# This does NOT deploy AgentCore, Lambda, networking, or SNS subscriptions.

# Resolve the same AWS account used by the existing workshop provider.
data "aws_caller_identity" "agentcore" {}

locals {
  agentcore_account_id = data.aws_caller_identity.agentcore.account_id
  agentcore_region     = var.aws_region
  agentcore_log_prefix = "arn:aws:logs:${local.agentcore_region}:${local.agentcore_account_id}:log-group:/aws/bedrock-agentcore/runtimes/*"
}

# The IAM role referenced by the official Step 7 setup_agentcore.sh.
resource "aws_iam_role" "agentcore_execution" {
  name        = "AgentCoreDBOpsRole"
  description = "DAT302 disposable lab: read-only Aurora health agent on Bedrock AgentCore Runtime"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowAgentCoreRuntime"
      Effect    = "Allow"
      Principal = { Service = "bedrock-agentcore.amazonaws.com" }
      Action    = "sts:AssumeRole"
      Condition = {
        StringEquals = {
          "aws:SourceAccount" = local.agentcore_account_id
        }
        ArnLike = {
          "aws:SourceArn" = "arn:aws:bedrock-agentcore:${local.agentcore_region}:${local.agentcore_account_id}:*"
        }
      }
    }]
  })

  tags = { Name = "DAT302-AgentCoreDBOpsRole" }
}

resource "aws_iam_role_policy" "agentcore_execution" {
  name = "DAT302AgentCoreExecutionPolicy"
  role = aws_iam_role.agentcore_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadWorkshopDatabaseSecret"
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
        Resource = aws_rds_cluster.lab.master_user_secret[0].secret_arn
      },
      {
        Sid      = "DiscoverWorkshopNotificationTopic"
        Effect   = "Allow"
        Action   = ["sns:ListTopics"]
        Resource = "*"
      },
      {
        Sid      = "PublishWorkshopNotifications"
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = aws_sns_topic.agentcore_notifications.arn
      },
      {
        Sid    = "InvokeWorkshopBedrockModels"
        Effect = "Allow"
        Action = ["bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream"]
        Resource = [
          "arn:aws:bedrock:*::foundation-model/*",
          "arn:aws:bedrock:${local.agentcore_region}:${local.agentcore_account_id}:inference-profile/*",
          "arn:aws:bedrock:${local.agentcore_region}:${local.agentcore_account_id}:application-inference-profile/*"
        ]
      },
      {
        Sid      = "FetchAgentContainerImages"
        Effect   = "Allow"
        Action   = ["ecr:BatchGetImage", "ecr:GetDownloadUrlForLayer"]
        Resource = "arn:aws:ecr:${local.agentcore_region}:${local.agentcore_account_id}:repository/*"
      },
      {
        Sid      = "AuthenticateToECR"
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Sid      = "AgentCoreLogGroupAccess"
        Effect   = "Allow"
        Action   = ["logs:DescribeLogStreams", "logs:CreateLogGroup", "logs:PutResourcePolicy"]
        Resource = local.agentcore_log_prefix
      },
      {
        Sid      = "AgentCoreDescribeLogGroups"
        Effect   = "Allow"
        Action   = ["logs:DescribeLogGroups"]
        Resource = "arn:aws:logs:${local.agentcore_region}:${local.agentcore_account_id}:log-group:*"
      },
      {
        Sid      = "AgentCoreLogStreams"
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "${local.agentcore_log_prefix}:log-stream:*"
      },
      {
        Sid      = "AgentCoreTracing"
        Effect   = "Allow"
        Action   = ["xray:PutTraceSegments", "xray:PutTelemetryRecords", "xray:GetSamplingRules", "xray:GetSamplingTargets"]
        Resource = "*"
      },
      {
        Sid      = "AgentCoreTelemetry"
        Effect   = "Allow"
        Action   = ["cloudwatch:PutMetricData"]
        Resource = "*"
        Condition = {
          StringEquals = { "cloudwatch:namespace" = "bedrock-agentcore" }
        }
      }
    ]
  })
}

# Used later by the optional AgentCore -> Lambda -> CloudWatch alarm module.
# The original setup-lambda-cwalarmtrigger.sh must be adapted to NOT create
# or overwrite this Terraform-managed role/policy (IAM drift otherwise).
resource "aws_iam_role" "dat302_lambda_invoker" {
  name        = "DatabaseOperationsInvokerRole"
  description = "DAT302 disposable lab: Lambda invokes the AgentCore health-check runtime"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = { Name = "DAT302-DatabaseOperationsInvokerRole" }
}

resource "aws_iam_role_policy" "dat302_lambda_invoker" {
  name = "DatabaseOperationsInvokerPolicy"
  role = aws_iam_role.dat302_lambda_invoker.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "CreateLambdaLogGroup"
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup"]
        Resource = "arn:aws:logs:${local.agentcore_region}:${local.agentcore_account_id}:*"
      },
      {
        Sid      = "WriteLambdaLogs"
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:${local.agentcore_region}:${local.agentcore_account_id}:log-group:/aws/lambda/database-operations-invoker:*"
      },
      {
        Sid    = "InvokeWorkshopAgentCoreRuntime"
        Effect = "Allow"
        Action = ["bedrock-agentcore:InvokeAgentRuntime"]
        Resource = [
          "arn:aws:bedrock-agentcore:${local.agentcore_region}:${local.agentcore_account_id}:runtime/*",
          "arn:aws:bedrock-agentcore:${local.agentcore_region}:${local.agentcore_account_id}:runtime/*/endpoint/*"
        ]
      }
    ]
  })
}

output "agentcore_execution_role_arn" {
  description = "Pass to the original AgentCore configure --execution-role argument"
  value       = aws_iam_role.agentcore_execution.arn
}

output "dat302_lambda_invoker_role_arn" {
  description = "Role for the optional CloudWatch alarm -> Lambda -> AgentCore module"
  value       = aws_iam_role.dat302_lambda_invoker.arn
}
