#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="us-east-1"

# Replace these values locally before running.
# Do NOT commit real secrets.
MONGO_URI_VALUE="REPLACE_WITH_MONGODB_ATLAS_URI"
JWT_SECRET_VALUE="REPLACE_WITH_STRONG_JWT_SECRET"

aws ssm put-parameter \
  --name "/muchtodo-month3/prod/mongo_uri" \
  --value "${MONGO_URI_VALUE}" \
  --type "SecureString" \
  --overwrite \
  --region "${AWS_REGION}"

aws ssm put-parameter \
  --name "/muchtodo-month3/prod/jwt_secret_key" \
  --value "${JWT_SECRET_VALUE}" \
  --type "SecureString" \
  --overwrite \
  --region "${AWS_REGION}"

echo "Application secrets stored safely in SSM Parameter Store."
