resource "aws_cloudwatch_log_group" "backend" {
  name              = "/aws/ec2/${local.name_prefix}/backend"
  retention_in_days = 14

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-backend-log-group"
  })
}
