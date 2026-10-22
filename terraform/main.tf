data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

# --- Isolated disposable VPC. No NAT gateway; the SSM tunnel box gets a public
# IP for outbound AWS Systems Manager connectivity, with NO inbound SG rules.
resource "aws_vpc" "lab" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "${var.name}-vpc" }
}

resource "aws_internet_gateway" "lab" {
  vpc_id = aws_vpc.lab.id
  tags   = { Name = "${var.name}-igw" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 10)
  availability_zone       = local.azs[0]
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.name}-ssm-public" }
}

resource "aws_subnet" "private" {
  count                   = 2
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 20)
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = false
  tags                    = { Name = "${var.name}-db-private-${count.index + 1}" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.lab.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab.id
  }
  tags = { Name = "${var.name}-public-rt" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_db_subnet_group" "lab" {
  name       = "${var.name}-db-subnets"
  subnet_ids = aws_subnet.private[*].id
  tags       = { Name = "${var.name}-db-subnets" }
}

resource "aws_security_group" "ssm" {
  name_prefix = "${var.name}-ssm-"
  description = "No ingress: only outbound TLS and database connection"
  vpc_id      = aws_vpc.lab.id
  tags        = { Name = "${var.name}-ssm-sg" }
}

resource "aws_vpc_security_group_egress_rule" "ssm_https" {
  security_group_id = aws_security_group.ssm.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Reach AWS Systems Manager endpoints over HTTPS"
}

resource "aws_vpc_security_group_egress_rule" "ssm_to_postgres" {
  security_group_id            = aws_security_group.ssm.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_security_group.db.id
  description                  = "SSM port forwarding to private Aurora"
}

resource "aws_security_group" "db" {
  name_prefix = "${var.name}-postgres-"
  description = "Aurora reachable only from disposable SSM jump host"
  vpc_id      = aws_vpc.lab.id
  tags        = { Name = "${var.name}-postgres-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "postgres_from_ssm" {
  security_group_id            = aws_security_group.db.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_security_group.ssm.id
  description                  = "DB connectivity from SSM-managed tunnel host only"
}

# SSM core role on the tiny jump host. Database and Bedrock permissions are
# deliberately not attached to this host; run agents from WSL2 via AWS profile.
resource "aws_iam_role" "ssm" {
  name = "${var.name}-ssm-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm" {
  name = "${var.name}-ssm-profile"
  role = aws_iam_role.ssm.name
}

resource "aws_instance" "ssm" {
  ami                         = data.aws_ssm_parameter.al2023.value
  instance_type               = var.ssm_instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.ssm.id]
  iam_instance_profile        = aws_iam_instance_profile.ssm.name
  associate_public_ip_address = true
  monitoring                  = false
  metadata_options {
    http_tokens = "required"
  }
  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }
  tags = { Name = "${var.name}-ssm-tunnel" }

  depends_on = [aws_iam_role_policy_attachment.ssm, aws_route_table_association.public]
}

# Aurora param settings for query-plan analysis and slow statement logs.
# Parameter names/apply methods must be validated against the selected engine
# version: aws rds describe-db-cluster-parameters / describe-db-engine-versions.
resource "aws_rds_cluster_parameter_group" "lab" {
  name        = "${var.name}-cluster-pg16"
  family      = "aurora-postgresql16"
  description = "DAT302 Aurora PG 16: plan ID and slow statement diagnostics"

  parameter {
    name         = "aurora_compute_plan_id"
    value        = "1"
    apply_method = "immediate"
  }

  parameter {
    name         = "log_min_duration_statement"
    value        = "1000"
    apply_method = "immediate"
  }
  tags = { Name = "${var.name}-params" }
}

resource "aws_cloudwatch_log_group" "postgres" {
  name              = "/aws/rds/cluster/${var.name}/postgresql"
  retention_in_days = 3
  tags              = { Name = "${var.name}-postgres-logs" }
}

resource "aws_rds_cluster" "lab" {
  cluster_identifier              = var.name
  engine                          = "aurora-postgresql"
  engine_version                  = var.aurora_engine_version
  database_name                   = var.db_name
  master_username                 = var.db_master_username
  manage_master_user_password     = true # RDS handles credential creation/rotation. No DB password in Terraform state.
  db_subnet_group_name            = aws_db_subnet_group.lab.name
  vpc_security_group_ids          = [aws_security_group.db.id]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.lab.name
  storage_encrypted               = true
  enabled_cloudwatch_logs_exports = ["postgresql"]

  database_insights_mode                = var.database_insights_mode
  performance_insights_enabled          = true
  performance_insights_retention_period = var.database_insights_mode == "advanced" ? 465 : 7

  backup_retention_period = 1
  deletion_protection     = false
  skip_final_snapshot     = true # DISPOSABLE LAB DATA ONLY
  apply_immediately       = true
  copy_tags_to_snapshot   = false
  tags                    = { Name = var.name }
  depends_on              = [aws_cloudwatch_log_group.postgres]
}

# Enhanced Monitoring for both instances (Database Insights correlation).
resource "aws_iam_role" "rds_monitoring" {
  name = "${var.name}-enhanced-monitoring"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "monitoring.rds.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_rds_cluster_instance" "writer" {
  identifier                 = "${var.name}-writer"
  cluster_identifier         = aws_rds_cluster.lab.id
  instance_class             = var.db_instance_class
  engine                     = aws_rds_cluster.lab.engine
  engine_version             = aws_rds_cluster.lab.engine_version
  publicly_accessible        = false
  auto_minor_version_upgrade = true
  monitoring_interval        = 60
  monitoring_role_arn        = aws_iam_role.rds_monitoring.arn
  apply_immediately          = true
  tags                       = { Name = "${var.name}-writer" }
  depends_on                 = [aws_iam_role_policy_attachment.rds_monitoring]
}

resource "aws_rds_cluster_instance" "reader" {
  count                      = var.reader_count
  identifier                 = "${var.name}-reader"
  cluster_identifier         = aws_rds_cluster.lab.id
  instance_class             = var.db_instance_class
  engine                     = aws_rds_cluster.lab.engine
  engine_version             = aws_rds_cluster.lab.engine_version
  publicly_accessible        = false
  auto_minor_version_upgrade = true
  monitoring_interval        = 60
  monitoring_role_arn        = aws_iam_role.rds_monitoring.arn
  apply_immediately          = true
  tags                       = { Name = "${var.name}-reader" }
  depends_on                 = [aws_iam_role_policy_attachment.rds_monitoring]
}

resource "aws_sns_topic" "alarms" {
  name = "${var.name}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_metric_alarm" "writer_cpu" {
  alarm_name          = "dat302-autodbops-labs-aurora-writer-cpu-alarm"
  alarm_description   = "DAT302 writer CPU over configured threshold - lab only"
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.cpu_alarm_threshold
  period              = 60
  evaluation_periods  = 2
  treat_missing_data  = "notBreaching"
  dimensions          = { DBInstanceIdentifier = aws_rds_cluster_instance.writer.identifier }
  alarm_actions       = [aws_sns_topic.alarms.arn]
  ok_actions          = [aws_sns_topic.alarms.arn]
  tags                = { Name = "${var.name}-writer-cpu" }
}
