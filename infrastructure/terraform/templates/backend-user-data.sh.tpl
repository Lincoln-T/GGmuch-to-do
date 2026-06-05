#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/opt/muchtodo"
SERVICE_NAME="muchtodo-backend"

apt-get update -y
apt-get install -y ca-certificates curl unzip git wget awscli

# Install Amazon CloudWatch Agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb -O /tmp/amazon-cloudwatch-agent.deb
dpkg -i /tmp/amazon-cloudwatch-agent.deb

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

cat > /etc/systemd/system/$${SERVICE_NAME}.service <<SERVICEEOF
[Unit]
Description=MuchToDo Backend API
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=$${APP_DIR}
EnvironmentFile=$${APP_DIR}/.env
ExecStart=/usr/local/bin/muchtodo-backend
Restart=always
RestartSec=5
StandardOutput=append:/var/log/muchtodo-backend.log
StandardError=append:/var/log/muchtodo-backend.log

[Install]
WantedBy=multi-user.target
SERVICEEOF

systemctl daemon-reload
systemctl enable $${SERVICE_NAME}

echo "Backend instance bootstrap completed. Application binary will be deployed by CI/CD." | tee -a /var/log/muchtodo-backend.log
