# Month 3 Deployment Guide

## Project Overview

This project deploys the MuchToDo full-stack application using AWS infrastructure and GitHub Actions.

The application contains:

- React/Vite frontend in `Client/`
- Golang backend API in `Server/MuchToDo/`
- Redis cache using Amazon ElastiCache
- MongoDB Atlas database
- S3 and CloudFront for frontend hosting
- EC2 Auto Scaling Group behind an Application Load Balancer for backend hosting
- CloudWatch Logs for backend logging
- GitHub Actions for CI/CD

## Architecture

The frontend is built with Vite and uploaded to a private S3 bucket. CloudFront serves the frontend over HTTPS.

The backend runs on EC2 instances managed by an Auto Scaling Group. The backend instances are registered behind an Application Load Balancer.

CloudFront routes:

- `/` to the frontend S3 origin
- `/api/*` to the backend ALB origin

The frontend uses:

`VITE_API_BASE_URL=/api`

This matches the application code because the frontend reads `import.meta.env.VITE_API_BASE_URL`. The backend app is built from `Server/MuchToDo/cmd/api/main.go`.

## Security

The project avoids committing secrets into GitHub.

The following files are ignored:

- `.env`
- `.env.*`
- `.tfvars`
- `.tfstate`
- `.terraform/`

Terraform state is stored remotely in an S3 backend instead of being committed to the repository.

Application secrets are stored in AWS SSM Parameter Store as SecureString parameters:

- `/muchtodo-month3/prod/mongo_uri`
- `/muchtodo-month3/prod/jwt_secret_key`

The backend EC2 role is allowed to read only the required SSM parameters.

GitHub Actions uses AWS OIDC instead of long-term AWS access keys.

## CI/CD

The repository includes two GitHub Actions workflows:

1. `terraform-checks.yml`
   - Runs Terraform format check
   - Runs Terraform validation

2. `deploy.yml`
   - Builds the frontend
   - Uploads frontend files to S3
   - Invalidates CloudFront cache
   - Builds the Golang backend binary
   - Uploads the backend binary to a private S3 artifact bucket
   - Deploys the backend binary to EC2 through AWS Systems Manager
   - Restarts the backend systemd service

## Required GitHub Secret

After Terraform creates the OIDC role, add this GitHub repository secret:

- `AWS_GITHUB_ACTIONS_ROLE_ARN`

## Required GitHub Repository Variables

After Terraform apply, add these repository variables from Terraform outputs:

- `FRONTEND_BUCKET_NAME`
- `CLOUDFRONT_DISTRIBUTION_ID`
- `BACKEND_ASG_NAME`
- `DEPLOYMENT_ARTIFACTS_BUCKET_NAME`

## Deployment Test

After deployment, test the application with:

`./scripts/test-deployment.sh <frontend_url> <backend_api_url>`

Example:

`./scripts/test-deployment.sh https://example.cloudfront.net https://example.cloudfront.net/api`

The script checks:

- Frontend response
- Backend root endpoint
- Backend `/ping` endpoint

## Important Notes

Do not commit real secrets, `.env` files, `.tfvars` files, or Terraform state files.

Do not expose the MongoDB Atlas URI or JWT secret in screenshots or documentation.

Confirm that the deployed frontend can call the backend through `/api`.

## Deployment Order

Use this order when deploying the project.

### 1. Bootstrap Terraform Remote State

Run the bootstrap script first so Terraform state is stored remotely:

`./scripts/bootstrap-terraform-state.sh`

This creates the S3 state bucket and DynamoDB lock table.

### 2. Create Application Secrets in SSM

Create the required SSM SecureString parameters:

- `/muchtodo-month3/prod/mongo_uri`
- `/muchtodo-month3/prod/jwt_secret_key`

A template script is available:

`./scripts/put-app-secrets.example.sh`

Before running it, replace the placeholder values locally. Do not commit real secrets.

### 3. Apply Terraform Infrastructure

From the Terraform directory, run Terraform plan and apply after reviewing the changes.

Terraform creates:

- VPC and public subnets
- Security groups
- Frontend S3 bucket
- CloudFront distribution
- Backend ALB
- Backend Auto Scaling Group
- ElastiCache Redis
- CloudWatch log group
- IAM roles and policies
- GitHub OIDC role
- Deployment artifact bucket

### 4. Add GitHub Secret and Variables

After Terraform apply, get the outputs using:

`./scripts/show-terraform-outputs.sh`

Add this GitHub repository secret:

- `AWS_GITHUB_ACTIONS_ROLE_ARN`

Add these GitHub repository variables:

- `FRONTEND_BUCKET_NAME`
- `CLOUDFRONT_DISTRIBUTION_ID`
- `BACKEND_ASG_NAME`
- `DEPLOYMENT_ARTIFACTS_BUCKET_NAME`

### 5. Run the Deployment Workflow

Push changes to the `month-three-assessment` branch or manually run the deploy workflow.

The workflow builds and deploys both frontend and backend.

### 6. Test the Deployment

Run:

`./scripts/test-deployment.sh <frontend_url> <backend_api_url>`

Example:

`./scripts/test-deployment.sh https://example.cloudfront.net https://example.cloudfront.net/api`

Confirm:

- Frontend loads successfully.
- Backend root endpoint works.
- Backend `/ping` endpoint works.
- Frontend API requests go through `/api`.
