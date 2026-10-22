variable "lab_acknowledged" {
  description = "Must be true to deploy billable, disposable lab infrastructure. Set only after reviewing cost and cleanup instructions."
  type        = bool
  default     = false

  validation {
    condition     = var.lab_acknowledged
    error_message = "Read README.md and explicitly set lab_acknowledged = true in terraform.tfvars to deploy this billable lab."
  }
}

variable "aws_region" {
  description = "Workshop agents default to us-west-2. Keep AWS CLI, Bedrock model and RDS in the same region."
  type        = string
  default     = "us-west-2"
}

variable "name" {
  description = "Original DAT302 cluster name. Keep as-is for maximum source-code compatibility."
  type        = string
  default     = "apgpg-dat302"
}

variable "vpc_cidr" {
  type    = string
  default = "10.82.0.0/16"
}

variable "db_name" {
  description = "Name of the initial database used by the seed and agents."
  type        = string
  default     = "hr_messy"
}

variable "db_master_username" {
  type    = string
  default = "postgres"
}

variable "aurora_engine_version" {
  description = "Must be an available Aurora PostgreSQL 16.x engine version in the chosen region. Verify before applying."
  type        = string
  default     = "16.10"

  validation {
    condition     = startswith(var.aurora_engine_version, "16.")
    error_message = "This sample uses the aurora-postgresql16 parameter-group family. Choose a supported 16.x engine version."
  }
}

variable "db_instance_class" {
  description = "Small burstable lab instance; raise to db.r6g.large for closer sustained-performance tests."
  type        = string
  default     = "db.t4g.medium"
}

variable "reader_count" {
  description = "Use 1 to match DAT302 writer + reader; 0 is cheaper but changes the workshop topology."
  type        = number
  default     = 1

  validation {
    condition     = contains([0, 1], var.reader_count)
    error_message = "For this lab reader_count must be 0 or 1."
  }
}

variable "database_insights_mode" {
  description = "advanced enables the full Database Insights investigation experience; advanced uses the required longer retention setting."
  type        = string
  default     = "advanced"

  validation {
    condition     = contains(["advanced", "standard"], var.database_insights_mode)
    error_message = "Use standard or advanced."
  }
}

variable "ssm_instance_type" {
  description = "Tiny jump box for SSM port-forwarding only; no inbound SSH."
  type        = string
  default     = "t3.nano"
}

variable "cpu_alarm_threshold" {
  description = "Percent CPU for demo CloudWatch alert."
  type        = number
  default     = 80
}

variable "alert_email" {
  description = "Optional SNS notification subscriber; must confirm subscription by email. Empty disables."
  type        = string
  default     = ""
}
