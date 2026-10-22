# DAT302 lab add-on: VPC connectivity for Bedrock AgentCore Runtime.
# Put this file in the existing DAT302-Terraform/terraform/ directory.
# This references the existing aws_vpc.lab, aws_subnet.public,
# aws_subnet.private, aws_route_table_association.public, and
# aws_security_group.db from main.tf. No existing resources are replaced.
#
# DESIGN: one public NAT gateway in the existing public subnet (AZ 1),
# shared by both existing private subnets. Cost-optimized for a disposable
# workshop, but NOT production HA. Private subnet traffic from AZ 2 can
# incur cross-AZ data-transfer charges. NAT Gateway/EIP accrue charges
# until destroyed. No inbound access from the internet is added.

# Outbound internet access for AgentCore network interfaces in private subnets.
resource "aws_eip" "agentcore_nat" {
  domain = "vpc"

  tags = { Name = "${var.name}-agentcore-nat-eip" }
}

resource "aws_nat_gateway" "agentcore" {
  allocation_id     = aws_eip.agentcore_nat.id
  subnet_id         = aws_subnet.public.id
  connectivity_type = "public"

  # Ensure the public subnet has its IGW default route before deploying NAT.
  depends_on = [aws_route_table_association.public]

  tags = { Name = "${var.name}-agentcore-nat" }
}

# The two private subnets were previously associated with the VPC's implicit
# main route table. Explicitly associate BOTH with this dedicated private RT.
resource "aws_route_table" "agentcore_private" {
  vpc_id = aws_vpc.lab.id

  tags = { Name = "${var.name}-agentcore-private-rt" }
}

resource "aws_route" "agentcore_private_ipv4_default" {
  route_table_id         = aws_route_table.agentcore_private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.agentcore.id
}

resource "aws_route_table_association" "agentcore_private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.agentcore_private.id

  depends_on = [aws_route.agentcore_private_ipv4_default]
}

# AgentCore/ECR container image layers use S3; a Gateway endpoint keeps that
# traffic within AWS and avoids NAT data-processing charges for this traffic.
# S3 gateway endpoints have no hourly or per-GB endpoint charge.
resource "aws_vpc_endpoint" "agentcore_s3" {
  vpc_id            = aws_vpc.lab.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.agentcore_private.id]

  tags = { Name = "${var.name}-agentcore-s3-gateway" }
}

# AgentCore runtime ENIs get their own SG, not the SSM or database SG.
# No inbound rules are needed for outbound-initiated DB and AWS calls.
resource "aws_security_group" "agentcore" {
  name_prefix = "${var.name}-agentcore-"
  description = "DAT302 AgentCore outbound HTTPS and Aurora PostgreSQL only"
  vpc_id      = aws_vpc.lab.id

  tags = { Name = "${var.name}-agentcore-sg" }
}

resource "aws_vpc_security_group_egress_rule" "agentcore_https" {
  security_group_id = aws_security_group.agentcore.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
  description       = "TLS to Bedrock, Secrets Manager, SNS, ECR and AWS APIs via NAT/S3 endpoint"
}

resource "aws_vpc_security_group_egress_rule" "agentcore_postgres" {
  security_group_id            = aws_security_group.agentcore.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_security_group.db.id
  description                  = "AgentCore runtime to Aurora PostgreSQL"
}

# Preserve existing SSM-to-DB ingress. Add one narrow ingress rule.
resource "aws_vpc_security_group_ingress_rule" "postgres_from_agentcore" {
  security_group_id            = aws_security_group.db.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_security_group.agentcore.id
  description                  = "Allow AgentCore runtime ENIs to reach Aurora PostgreSQL"
}

# Feed these existing resource IDs to the WORKSHOP's `agentcore configure`
# when we adapt the original setup script. Do not run the script yet.
output "agentcore_security_group_id" {
  description = "Dedicated AgentCore VPC-mode runtime security group"
  value       = aws_security_group.agentcore.id
}

output "agentcore_private_subnet_ids" {
  description = "Existing two private subnet IDs for AgentCore Runtime"
  value       = aws_subnet.private[*].id
}

output "agentcore_nat_gateway_id" {
  description = "NAT gateway shared by the two private lab subnets"
  value       = aws_nat_gateway.agentcore.id
}

output "agentcore_nat_public_ip" {
  description = "Public IPv4 used by AgentCore private-subnet NAT egress"
  value       = aws_eip.agentcore_nat.public_ip
}
