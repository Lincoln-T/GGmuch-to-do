#!/usr/bin/env bash
set -euo pipefail

PROJECT_NAME="muchtodo-month3"
AWS_REGION="us-east-1"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"

STATE_BUCKET="${PROJECT_NAME}-terraform-state-${ACCOUNT_ID}"
LOCK_TABLE="${PROJECT_NAME}-terraform-locks"

echo "Using AWS account: ${ACCOUNT_ID}"
echo "Region: ${AWS_REGION}"
echo "State bucket: ${STATE_BUCKET}"
echo "Lock table: ${LOCK_TABLE}"

echo "Checking if S3 bucket exists..."
if aws s3api head-bucket --bucket "${STATE_BUCKET}" 2>/dev/null; then
  echo "S3 bucket already exists: ${STATE_BUCKET}"
else
  echo "Creating S3 bucket: ${STATE_BUCKET}"
  aws s3api create-bucket \
    --bucket "${STATE_BUCKET}" \
    --region "${AWS_REGION}"
fi

echo "Enabling S3 bucket versioning..."
aws s3api put-bucket-versioning \
  --bucket "${STATE_BUCKET}" \
  --versioning-configuration Status=Enabled

echo "Enabling default encryption..."
aws s3api put-bucket-encryption \
  --bucket "${STATE_BUCKET}" \
  --server-side-encryption-configuration '{
    "Rules": [
      {
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        }
      }
    ]
  }'

echo "Blocking all public access..."
aws s3api put-public-access-block \
  --bucket "${STATE_BUCKET}" \
  --public-access-block-configuration '{
    "BlockPublicAcls": true,
    "IgnorePublicAcls": true,
    "BlockPublicPolicy": true,
    "RestrictPublicBuckets": true
  }'

echo "Checking if DynamoDB lock table exists..."
if aws dynamodb describe-table --table-name "${LOCK_TABLE}" --region "${AWS_REGION}" >/dev/null 2>&1; then
  echo "DynamoDB table already exists: ${LOCK_TABLE}"
else
  echo "Creating DynamoDB table: ${LOCK_TABLE}"
  aws dynamodb create-table \
    --table-name "${LOCK_TABLE}" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "${AWS_REGION}"

  echo "Waiting for DynamoDB table to become active..."
  aws dynamodb wait table-exists \
    --table-name "${LOCK_TABLE}" \
    --region "${AWS_REGION}"
fi

echo ""
echo "Remote Terraform state bootstrap complete."
echo ""
echo "Use these values in backend.tf:"
echo "bucket         = \"${STATE_BUCKET}\""
echo "key            = \"month3/prod/terraform.tfstate\""
echo "region         = \"${AWS_REGION}\""
echo "dynamodb_table = \"${LOCK_TABLE}\""
echo "encrypt        = true"
