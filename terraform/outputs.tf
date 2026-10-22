output "aws_region" {
  value = var.aws_region
}

output "aurora_cluster_id" {
  value = aws_rds_cluster.lab.id
}

output "aurora_writer_endpoint" {
  value = aws_rds_cluster.lab.endpoint
}

output "aurora_reader_endpoint" {
  value = aws_rds_cluster.lab.reader_endpoint
}

output "aurora_master_secret_arn" {
  value       = aws_rds_cluster.lab.master_user_secret[0].secret_arn
  description = "RDS-managed secret ARN; Terraform does not read its password."
}

output "database_name" {
  value = var.db_name
}

output "ssm_instance_id" {
  value       = aws_instance.ssm.id
  description = "SSM jump host; has no inbound security-group rules."
}

output "cloudwatch_alarm_name" {
  value = aws_cloudwatch_metric_alarm.writer_cpu.alarm_name
}

output "database_insights_mode" {
  value = aws_rds_cluster.lab.database_insights_mode
}

output "approximate_chargeable_resources" {
  value = "Aurora ${1 + var.reader_count} x ${var.db_instance_class}, Aurora storage/I-O, Database Insights, EC2 ${var.ssm_instance_type} + public IPv4, EBS, logs, SNS, Bedrock usage."
}
