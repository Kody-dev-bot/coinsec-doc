#!/bin/bash
BACKUP_DIR="/opt/accounting/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

# 备份MariaDB
mysqldump -u account_user -p'你的密码' accounting > $BACKUP_DIR/accounting_$TIMESTAMP.sql

# 保留最近30天的备份
find $BACKUP_DIR -name "accounting_*.sql" -type f -mtime +30 -delete