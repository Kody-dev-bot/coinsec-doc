#!/bin/bash
# 版本回滚脚本：./rollback.sh 历史版本备份jar路径

# 配置参数（同deploy.sh）
APP_NAME="accounting"
APP_DIR="/opt/accounting"
BACKUP_DIR="${APP_DIR}/backups"
SERVICE_NAME="accounting.service"

# 检查参数（需传入历史备份jar包路径）
if [ $# -ne 1 ]; then
  echo "用法：./rollback.sh 历史备份jar路径（如./backups/accounting-v1.0.jar.backup-202409011000）"
  exit 1
fi
BACKUP_JAR_PATH=$1

# 检查备份jar包是否存在
if [ ! -f "$BACKUP_JAR_PATH" ]; then
  echo "错误：备份jar包不存在！"
  exit 1
fi

# 1. 停止当前服务
echo "===== 停止当前服务 ====="
sudo systemctl stop $SERVICE_NAME

# 2. 恢复jar包（从备份复制到当前版本）
echo "===== 恢复历史版本 ====="
HISTORY_JAR_NAME=$(basename $BACKUP_JAR_PATH | sed 's/.backup-.*//') # 提取原始jar名（如accounting-v1.0.jar）
cp $BACKUP_JAR_PATH ${APP_DIR}/$HISTORY_JAR_NAME
# 更新软链接
ln -snf ${APP_DIR}/$HISTORY_JAR_NAME ${APP_DIR}/current.jar
echo "已恢复版本：${APP_DIR}/$HISTORY_JAR_NAME"

# 3. （可选）恢复数据库（若新版本修改了数据库结构）
echo "===== 提示：若新版本执行过数据库脚本，需手动恢复数据库 ====="
echo "可使用备份的SQL文件：ls ${APP_DIR}/backups/accounting_*.sql"
read -p "是否现在恢复数据库？(y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  # 列出最近的数据库备份
  echo "最近的数据库备份："
  ls -lt ${APP_DIR}/backups/accounting_*.sql | head -n 3
  read -p "请输入要恢复的SQL文件路径：" SQL_FILE
  if [ -f "$SQL_FILE" ]; then
    mysql -u account_user -p accounting < $SQL_FILE
    echo "数据库恢复完成"
  else
    echo "SQL文件不存在，跳过数据库恢复"
  fi
fi

# 4. 重启服务
echo "===== 重启服务 ====="
sudo systemctl start $SERVICE_NAME
sleep 3

# 5. 检查服务状态
echo "===== 检查服务状态 ====="
if sudo systemctl is-active --quiet $SERVICE_NAME; then
  echo "版本回滚成功！当前版本：$HISTORY_JAR_NAME"
  sudo journalctl -u $SERVICE_NAME --no-pager -n 20
else
  echo "错误：服务启动失败，请查看日志排查问题！"
  exit 1
fi