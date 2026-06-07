#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/opt/muchtodo"
SERVICE_NAME="muchtodo-backend"
CONTAINER_NAME="muchtodo-backend"
BACKEND_IMAGE_URI="${backend_image_uri}"

apt-get update -y
apt-get install -y ca-certificates curl unzip git wget awscli snapd docker.io

systemctl enable docker
systemctl start docker

# Install Amazon CloudWatch Agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb -O /tmp/amazon-cloudwatch-agent.deb
dpkg -i /tmp/amazon-cloudwatch-agent.deb

# Ensure AWS Systems Manager agent is installed and running
if ! command -v snap >/dev/null 2>&1; then
  apt-get install -y snapd
fi

if ! systemctl list-unit-files | grep -q snap.amazon-ssm-agent.amazon-ssm-agent.service; then
  snap install amazon-ssm-agent --classic || true
fi

systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service || true
systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service || true

mkdir -p "$${APP_DIR}"

MONGO_URI_VALUE="$(aws ssm get-parameter --name "${mongo_uri_parameter_name}" --with-decryption --region "${aws_region}" --query Parameter.Value --output text)"
JWT_SECRET_VALUE="$(aws ssm get-parameter --name "${jwt_secret_parameter_name}" --with-decryption --region "${aws_region}" --query Parameter.Value --output text)"

cat > "$${APP_DIR}/.env" <<ENVEOF
PORT=${backend_port}
ALLOWED_ORIGINS=*
COOKIE_DOMAINS=
SECURE_COOKIE=false
MONGO_URI=$${MONGO_URI_VALUE}
DB_NAME=muchtodo
JWT_SECRET_KEY=$${JWT_SECRET_VALUE}
JWT_EXPIRATION_HOURS=24
ENABLE_CACHE=true
REDIS_ADDR=${redis_addr}
REDIS_PASSWORD=
LOG_LEVEL=info
LOG_FORMAT=json
ENVEOF

chmod 600 "$${APP_DIR}/.env"

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<CWEOF
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/cloud-init-output.log",
            "log_group_name": "${cloudwatch_log_group}",
            "log_stream_name": "{instance_id}/cloud-init-output.log"
          },
          {
            "file_path": "/var/log/muchtodo-backend.log",
            "log_group_name": "${cloudwatch_log_group}",
            "log_stream_name": "{instance_id}/muchtodo-backend.log"
          }
        ]
      }
    }
  }
}
CWEOF

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s

cat > /usr/local/bin/deploy-muchtodo-container <<'DEPLOYEOF'
#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${aws_region}"
CONTAINER_NAME="muchtodo-backend"
IMAGE_URI="${backend_image_uri}"
APP_ENV_FILE="/opt/muchtodo/.env"
LOG_FILE="/var/log/muchtodo-backend.log"

aws ecr get-login-password --region "$${AWS_REGION}" | \
  docker login --username AWS --password-stdin "$${IMAGE_URI%/*}"

docker pull "$${IMAGE_URI}"

docker rm -f "$${CONTAINER_NAME}" 2>/dev/null || true

docker run -d \
  --name "$${CONTAINER_NAME}" \
  --restart unless-stopped \
  --env-file "$${APP_ENV_FILE}" \
  -p ${backend_port}:${backend_port} \
  "$${IMAGE_URI}"

docker logs -f "$${CONTAINER_NAME}" >> "$${LOG_FILE}" 2>&1 &
DEPLOYEOF

chmod +x /usr/local/bin/deploy-muchtodo-container

cat > /etc/systemd/system/$${SERVICE_NAME}.service <<SERVICEEOF
[Unit]
Description=MuchToDo Backend API Docker Container
After=network-online.target docker.service
Wants=network-online.target
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/deploy-muchtodo-container
ExecStop=/usr/bin/docker rm -f $${CONTAINER_NAME}
TimeoutStartSec=300

[Install]
WantedBy=multi-user.target
SERVICEEOF

systemctl daemon-reload
systemctl enable $${SERVICE_NAME}
systemctl start $${SERVICE_NAME}

echo "Backend instance bootstrap completed. Docker image deployment service started." | tee -a /var/log/muchtodo-backend.log
