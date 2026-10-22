# DAT302: AgentCore health-check notifications.
# Deliberately separate from aws_sns_topic.alarms, which notifies about
# CloudWatch Aurora CPU alarms.
resource "aws_sns_topic" "agentcore_notifications" {
  name = "agentcore-database-alerts"

  tags = {
    Name = "DAT302-AgentCoreNotifications"
  }
}

# Reuse the existing optional alert_email variable. The email subscription
# is separately confirmed for this SNS topic via the AWS confirmation email.
resource "aws_sns_topic_subscription" "agentcore_email" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.agentcore_notifications.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

output "agentcore_notifications_topic_arn" {
  description = "SNS topic ARN used by AgentCore health-check notifications"
  value       = aws_sns_topic.agentcore_notifications.arn
}
