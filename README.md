
---

# Month 3 Assessment: Full-Stack CI/CD Deployment

## Overview

This repository contains the Month 3 assessment implementation for deploying the MuchToDo full-stack application using AWS and GitHub Actions.

The application includes:

- React/Vite frontend located in `Client/`
- Golang backend API located in `Server/MuchToDo/`
- Redis cache using Amazon ElastiCache
- MongoDB Atlas for database persistence
- S3 and CloudFront for frontend hosting
- EC2 Auto Scaling Group behind an Application Load Balancer for backend hosting
- CloudWatch Logs for backend observability
- GitHub Actions for CI/CD automation

## Deployment Architecture

The frontend is built using:

`npm run build`

The frontend build output is uploaded to a private S3 bucket and served through CloudFront.

The backend is built from:

`Server/MuchToDo/cmd/api/main.go`

The backend binary is deployed to EC2 instances through AWS Systems Manager.

CloudFront routes frontend and backend traffic:

- `/` serves the React frontend from S3
- `/api/*` forwards API requests to the backend ALB

The frontend uses:

`VITE_API_BASE_URL=/api`

This matches the frontend application configuration, where the API client reads `import.meta.env.VITE_API_BASE_URL`. The backend also provides `/` and `/ping` routes that can be used for testing deployment health. :contentReference[oaicite:0]{index=0}

## Security

This project avoids committing secrets or sensitive state files.

The `.gitignore` excludes:

- `.env`
- `.env.*`
- `.tfvars`
- `terraform.tfstate`
- `terraform.tfstate.*`
- `.terraform/`

Terraform state is stored using a remote S3 backend.

Application secrets are stored in AWS SSM Parameter Store as SecureString values:

- `/muchtodo-month3/prod/mongo_uri`
- `/muchtodo-month3/prod/jwt_secret_key`

GitHub Actions uses AWS OIDC instead of long-term AWS access keys.

## CI/CD Workflows

The repository includes:

### Terraform Checks

`.github/workflows/terraform-checks.yml`

This workflow checks Terraform formatting and validates the Terraform configuration.

### Application Deployment

`.github/workflows/deploy.yml`

This workflow:

1. Builds the React frontend.
2. Uploads the frontend build to S3.
3. Invalidates CloudFront.
4. Builds the Golang backend binary.
5. Uploads the backend binary to a private S3 artifact bucket.
6. Uses AWS Systems Manager to deploy the backend binary to EC2.
7. Restarts the backend systemd service.

## Required GitHub Configuration

After Terraform creates the infrastructure, configure this GitHub repository secret:

- `AWS_GITHUB_ACTIONS_ROLE_ARN`

Configure these GitHub repository variables:

- `FRONTEND_BUCKET_NAME`
- `CLOUDFRONT_DISTRIBUTION_ID`
- `BACKEND_ASG_NAME`
- `DEPLOYMENT_ARTIFACTS_BUCKET_NAME`

These values come from Terraform outputs.

## Deployment Test

After deployment, test the frontend and backend using:

`./scripts/test-deployment.sh <frontend_url> <backend_api_url>`

Example:

`./scripts/test-deployment.sh https://example.cloudfront.net https://example.cloudfront.net/api`

## Important Notes

Do not commit:

- AWS credentials
- MongoDB Atlas URI
- JWT secret
- Real `.env` files
- `.tfvars` files
- Terraform state files

