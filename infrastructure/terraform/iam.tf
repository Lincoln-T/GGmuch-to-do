resource "aws_iam_role" "backend_ec2" {
  name = "${local.name_prefix}-backend-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-backend-ec2-role"
  })
}

resource "aws_iam_policy" "backend_cloudwatch_logs" {
  name        = "${local.name_prefix}-backend-cloudwatch-logs-policy"
  description = "Allow backend EC2 instances to write application logs to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowWritingApplicationLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = [
          "${aws_cloudwatch_log_group.backend.arn}:*"
        ]
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-backend-cloudwatch-logs-policy"
  })
}

resource "aws_iam_role_policy_attachment" "backend_cloudwatch_logs" {
  role       = aws_iam_role.backend_ec2.name
  policy_arn = aws_iam_policy.backend_cloudwatch_logs.arn
}

resource "aws_iam_instance_profile" "backend_ec2" {
  name = "${local.name_prefix}-backend-ec2-profile"
  role = aws_iam_role.backend_ec2.name

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-backend-ec2-profile"
  })
}

resource "aws_iam_policy" "backend_ssm_parameters" {
  name        = "${local.name_prefix}-backend-ssm-parameters-policy"
  description = "Allow backend EC2 instances to read required application secrets from SSM Parameter Store"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowReadBackendParameters"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter"
        ]
        Resource = [
          "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${var.mongo_uri_parameter_name}",
          "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${var.jwt_secret_parameter_name}"
        ]
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-backend-ssm-parameters-policy"
  })
}

resource "aws_iam_role_policy_attachment" "backend_ssm_parameters" {
  role       = aws_iam_role.backend_ec2.name
  policy_arn = aws_iam_policy.backend_ssm_parameters.arn
}

resource "aws_iam_role_policy_attachment" "backend_ssm_managed_instance_core" {
  role       = aws_iam_role.backend_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
