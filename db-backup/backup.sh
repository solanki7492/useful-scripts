#!/bin/bash

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BASE_DIR/config.env"

LOG_DIR="$BASE_DIR/logs"
TMP_DIR="$BASE_DIR/backups"

mkdir -p "$LOG_DIR" "$TMP_DIR"

LOG_FILE="$LOG_DIR/backup.log"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M")
FILENAME="${PROJECT_NAME}_${DB_NAME}_${TIMESTAMP}.sql"
ARCHIVE="${FILENAME}.gz"

echo "[$(date)] Backup started" >> "$LOG_FILE"

# DATABASE DUMP
if [ "$DB_TYPE" == "mysql" ]; then
  mysqldump \
    -h "$DB_HOST" \
    -P "${DB_PORT:-3306}" \
    -u "$DB_USER" \
    -p"$DB_PASS" \
    "$DB_NAME" > "$TMP_DIR/$FILENAME"

elif [ "$DB_TYPE" == "postgres" ]; then
  export PGPASSWORD="$DB_PASS"
  pg_dump \
    -h "$DB_HOST" \
    -p "${DB_PORT:-5432}" \
    -U "$DB_USER" \
    "$DB_NAME" > "$TMP_DIR/$FILENAME"
fi

gzip "$TMP_DIR/$FILENAME"

# STORAGE HANDLING
if [ "$STORAGE_TYPE" == "local" ]; then
  mkdir -p "$LOCAL_PATH"
  mv "$TMP_DIR/$ARCHIVE" "$LOCAL_PATH/"

elif [ "$STORAGE_TYPE" == "ftp" ]; then
  lftp -u "$FTP_USER","$FTP_PASS" -p "$FTP_PORT" "$FTP_HOST" <<EOF
  mkdir -p $FTP_PATH
  put $TMP_DIR/$ARCHIVE -o $FTP_PATH/$ARCHIVE
  bye
EOF
  rm -f "$TMP_DIR/$ARCHIVE"

elif [ "$STORAGE_TYPE" == "s3" ]; then
  export AWS_ACCESS_KEY_ID="$S3_KEY"
  export AWS_SECRET_ACCESS_KEY="$S3_SECRET"
  export AWS_DEFAULT_REGION="$S3_REGION"

  EXTRA=""
  [ -n "$S3_ENDPOINT" ] && EXTRA="--endpoint-url $S3_ENDPOINT"

  aws s3 cp "$TMP_DIR/$ARCHIVE" "s3://$S3_BUCKET/$ARCHIVE" $EXTRA
  rm -f "$TMP_DIR/$ARCHIVE"
fi

# RETENTION
find "$LOCAL_PATH" -type f -mtime +"$RETENTION_DAYS" -delete 2>/dev/null

echo "[$(date)] Backup completed" >> "$LOG_FILE"
