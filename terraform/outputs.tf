output "project_name" {
  value = var.project_name
}

output "aws_region" {
  value = var.aws_region
}

output "redis_endpoint" {
  description = "Redis ElastiCache endpoint address"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
}

output "frontend_bucket_name" {
  description = "S3 bucket used for frontend static files"
  value       = aws_s3_bucket.frontend.bucket
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.frontend.id
}

output "frontend_url" {
  description = "CloudFront frontend URL"
  value       = "https://${aws_cloudfront_distribution.frontend.domain_name}"
}

output "backend_alb_dns_name" {
  description = "Backend Application Load Balancer DNS name"
  value       = aws_lb.backend.dns_name
}

output "backend_api_url" {
  description = "Backend API URL through CloudFront"
  value       = "https://${aws_cloudfront_distribution.frontend.domain_name}/api"
}

output "backend_asg_name" {
  description = "Backend Auto Scaling Group name"
  value       = aws_autoscaling_group.backend.name
}

output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions OIDC deployment"
  value       = aws_iam_role.github_actions_deploy.arn
}

output "deployment_artifacts_bucket_name" {
  description = "S3 bucket used for backend deployment artifacts"
  value       = aws_s3_bucket.deployment_artifacts.bucket
}

output "backend_ecr_repository_url" {
  description = "ECR repository URL for backend Docker images"
  value       = aws_ecr_repository.backend.repository_url
}
