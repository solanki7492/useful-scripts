#!/bin/bash

CONFIG_FILE="$(pwd)/config.env"

echo "=============================="
echo " Database Backup Setup Wizard "
echo "=============================="

read -p "Project name (used in backup filename): " PROJECT_NAME

# DB TYPE
echo "Select database type:"
echo "1) MySQL / MariaDB"
echo "2) PostgreSQL"
read -p "Enter choice [1-2]: " DB_CHOICE

if [ "$DB_CHOICE" == "1" ]; then
  DB_TYPE="mysql"
elif [ "$DB_CHOICE" == "2" ]; then
  DB_TYPE="postgres"
else
  echo "Invalid choice"
  exit 1
fi

read -p "Database host (default: localhost): " DB_HOST
DB_HOST=${DB_HOST:-localhost}

read -p "Database port (press enter for default): " DB_PORT
read -p "Database name: " DB_NAME
read -p "Database user: " DB_USER
read -s -p "Database password: " DB_PASS
echo ""

# STORAGE
echo ""
echo "Select backup storage:"
echo "1) Local directory"
echo "2) FTP server"
echo "3) S3 / S3-compatible (AWS, DO Spaces, Wasabi)"
read -p "Enter choice [1-3]: " STORAGE_CHOICE

if [ "$STORAGE_CHOICE" == "1" ]; then
  STORAGE_TYPE="local"
  read -p "Local backup directory (absolute path): " LOCAL_PATH

elif [ "$STORAGE_CHOICE" == "2" ]; then
  STORAGE_TYPE="ftp"
  read -p "FTP host: " FTP_HOST
  read -p "FTP port (default 21): " FTP_PORT
  FTP_PORT=${FTP_PORT:-21}
  read -p "FTP username: " FTP_USER
  read -s -p "FTP password: " FTP_PASS
  echo ""
  read -p "FTP remote directory: " FTP_PATH

elif [ "$STORAGE_CHOICE" == "3" ]; then
  STORAGE_TYPE="s3"
  read -p "S3 bucket name: " S3_BUCKET
  read -p "S3 region (e.g. us-east-1): " S3_REGION
  read -p "S3 access key: " S3_KEY
  read -s -p "S3 secret key: " S3_SECRET
  echo ""
  read -p "S3 endpoint (leave empty for AWS): " S3_ENDPOINT

else
  echo "Invalid choice"
  exit 1
fi

# RETENTION
read -p "How many days to keep backups? (e.g. 7, 14, 30): " RETENTION_DAYS

# WRITE CONFIG
cat > "$CONFIG_FILE" <<EOF
PROJECT_NAME="$PROJECT_NAME"

DB_TYPE="$DB_TYPE"
DB_HOST="$DB_HOST"
DB_PORT="$DB_PORT"
DB_NAME="$DB_NAME"
DB_USER="$DB_USER"
DB_PASS="$DB_PASS"

STORAGE_TYPE="$STORAGE_TYPE"

LOCAL_PATH="$LOCAL_PATH"

FTP_HOST="$FTP_HOST"
FTP_PORT="$FTP_PORT"
FTP_USER="$FTP_USER"
FTP_PASS="$FTP_PASS"
FTP_PATH="$FTP_PATH"

S3_BUCKET="$S3_BUCKET"
S3_REGION="$S3_REGION"
S3_KEY="$S3_KEY"
S3_SECRET="$S3_SECRET"
S3_ENDPOINT="$S3_ENDPOINT"

RETENTION_DAYS="$RETENTION_DAYS"
EOF

chmod 600 "$CONFIG_FILE"

echo ""
echo "Setup complete ✅"
echo "Config saved to: $CONFIG_FILE"
echo "Next step: add cron job for backup.sh"
