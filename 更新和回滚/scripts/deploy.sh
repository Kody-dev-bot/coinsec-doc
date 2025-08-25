#!/bin/bash
# 版本更新脚本：./deploy.sh 新版本jar包路径

# 配置参数
APP_NAME="accounting"          # 应用名称
APP_DIR="/opt/accounting"      # 应用目录
BACKUP_DIR="${APP_DIR}/backups" # 备份目录
MAX_BACKUP=5                   # 保留最多5个历史版本
SERVICE_NAME="accounting.service" # systemd服务名

# 检查参数（需传入新版本jar包路径）
if [ $# -ne 1 ]; then
  echo "用法：./deploy.sh 新版本jar包路径（如./accounting-v1.1.jar）"
  exit 1
fi
NEW_JAR_PATH=$1
NEW_JAR_NAME=$(basename $NEW_JAR_PATH)

# 检查新版本jar包是否存在
if [ ! -f "$NEW_JAR_PATH" ]; then
  echo "错误：新版本jar包不存在！"
  exit 1
fi

# 1. 备份当前版本（若存在）
echo "===== 备份当前版本 ====="
CURRENT_JAR=$(ls ${APP_DIR}/${APP_NAME}-*.jar 2>/dev/null | head -n 1) # 获取当前运行的jar包
if [ -n "$CURRENT_JAR" ]; then
  # 创建备份目录
  mkdir -p $BACKUP_DIR
  # 备份jar包（带时间戳）
  BACKUP_JAR="${BACKUP_DIR}/$(basename $CURRENT_JAR).backup-$(date +%Y%m%d%H%M)"
  cp $CURRENT_JAR $BACKUP_JAR
  echo "已备份当前版本到：$BACKUP_JAR"
  
  # 清理旧备份（只保留最近5个）
  echo "清理旧备份（保留最近${MAX_BACKUP}个）"
  ls -tp ${BACKUP_DIR}/*.backup-* | grep -v '/$' | tail -n +$(($MAX_BACKUP + 1)) | xargs -I {} rm -- {}
else
  echo "当前无运行的jar包，跳过备份"
fi

# 2. 备份数据库（关键！更新前确保数据可恢复）
echo "===== 备份数据库 ====="
${APP_DIR}/backup.sh  # 调用之前的数据库备份脚本（生成带时间戳的SQL文件）

# 3. 部署新版本
echo "===== 部署新版本 ====="
cp $NEW_JAR_PATH ${APP_DIR}/$NEW_JAR_NAME
# 创建软链接（方便启动脚本固定引用）
ln -snf ${APP_DIR}/$NEW_JAR_NAME ${APP_DIR}/current.jar
echo "已部署新版本：${APP_DIR}/$NEW_JAR_NAME"

# 4. 重启服务（通过systemd）
echo "===== 重启服务 ====="
sudo systemctl restart $SERVICE_NAME
sleep 3  # 等待服务启动

# 5. 检查服务状态
echo "===== 检查服务状态 ====="
if sudo systemctl is-active --quiet $SERVICE_NAME; then
  echo "版本更新成功！当前版本：$NEW_JAR_NAME"
  # 输出最新日志（方便快速确认启动状态）
  sudo journalctl -u $SERVICE_NAME --no-pager -n 20
else
  echo "错误：服务启动失败，请查看日志排查问题！"
  exit 1
fi