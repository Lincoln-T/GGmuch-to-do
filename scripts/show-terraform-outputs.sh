#!/usr/bin/env bash
set -euo pipefail

TERRAFORM_DIR="infrastructure/terraform"

echo "Frontend bucket:"
terraform -chdir="${TERRAFORM_DIR}" output -raw frontend_bucket_name

echo ""
echo "CloudFront distribution ID:"
terraform -chdir="${TERRAFORM_DIR}" output -raw cloudfront_distribution_id

echo ""
echo "Frontend URL:"
terraform -chdir="${TERRAFORM_DIR}" output -raw frontend_url

echo ""
echo "Backend API URL:"
terraform -chdir="${TERRAFORM_DIR}" output -raw backend_api_url

echo ""
echo "Backend ASG name:"
terraform -chdir="${TERRAFORM_DIR}" output -raw backend_asg_name

echo ""
echo "Deployment artifacts bucket:"
terraform -chdir="${TERRAFORM_DIR}" output -raw deployment_artifacts_bucket_name

echo ""
echo "GitHub Actions role ARN:"
terraform -chdir="${TERRAFORM_DIR}" output -raw github_actions_role_arn
