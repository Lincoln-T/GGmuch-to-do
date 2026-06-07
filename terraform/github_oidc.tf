resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-github-oidc-provider"
  })
}

resource "aws_iam_role" "github_actions_deploy" {
  name = "${local.name_prefix}-github-actions-deploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_owner}/${var.github_repo}:ref:refs/heads/${var.github_branch}"
          }
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-github-actions-deploy-role"
  })
}

resource "aws_iam_policy" "github_actions_deploy" {
  name        = "${local.name_prefix}-github-actions-deploy-policy"
  description = "Least-privilege deployment permissions for MuchToDo GitHub Actions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowFrontendS3Deployment"
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.frontend.arn
        ]
      },
      {
        Sid    = "AllowFrontendS3ObjectDeployment"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:GetObject"
        ]
        Resource = [
          "${aws_s3_bucket.frontend.arn}/*"
        ]
      },
      {
        Sid    = "AllowCloudFrontInvalidation"
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation",
          "cloudfront:GetDistribution",
          "cloudfront:GetInvalidation"
        ]
        Resource = [
          aws_cloudfront_distribution.frontend.arn
        ]
      },
      {
        Sid    = "AllowReadDeploymentTargets"
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "ssm:DescribeInstanceInformation"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowBackendDeploymentViaSSM"
        Effect = "Allow"
        Action = [
          "ssm:SendCommand",
          "ssm:GetCommandInvocation",
          "ssm:ListCommandInvocations"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-github-actions-deploy-policy"
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_deploy" {
  role       = aws_iam_role.github_actions_deploy.name
  policy_arn = aws_iam_policy.github_actions_deploy.arn
}

resource "aws_iam_policy" "github_actions_artifact_deploy" {
  name        = "${local.name_prefix}-github-actions-artifact-deploy-policy"
  description = "Allow GitHub Actions to upload backend deployment artifacts"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowListDeploymentArtifactsBucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.deployment_artifacts.arn
        ]
      },
      {
        Sid    = "AllowWriteDeploymentArtifacts"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = [
          "${aws_s3_bucket.deployment_artifacts.arn}/backend/*"
        ]
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-github-actions-artifact-deploy-policy"
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_artifact_deploy" {
  role       = aws_iam_role.github_actions_deploy.name
  policy_arn = aws_iam_policy.github_actions_artifact_deploy.arn
}

resource "aws_iam_policy" "github_actions_ecr_push" {
  name        = "${local.name_prefix}-github-actions-ecr-push-policy"
  description = "Allow GitHub Actions to build and push backend Docker images to ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEcrAuth"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowPushBackendImage"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
          "ecr:DescribeRepositories",
          "ecr:DescribeImages"
        ]
        Resource = aws_ecr_repository.backend.arn
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-github-actions-ecr-push-policy"
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_ecr_push" {
  role       = aws_iam_role.github_actions_deploy.name
  policy_arn = aws_iam_policy.github_actions_ecr_push.arn
}
