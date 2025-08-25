### 一、磁盘碎片清理（每月1次手动检查+处理）
磁盘碎片主要产生于频繁“删除/修改”的数据库表（如`account_record`），长期不清理会导致磁盘IO变慢。MariaDB（InnoDB引擎）的碎片清理可通过`OPTIMIZE TABLE`命令完成，操作步骤如下：


#### 1. 检查磁盘碎片情况
登录阿里云ECS，执行以下命令查看目标表的碎片率：
```bash
# 1. 登录MariaDB（替换为你的数据库用户和密码）
mysql -u account_user -p

# 2. 切换到记账数据库
USE accounting;

# 3. 查看指定表的碎片情况（重点检查高频操作的表）
SELECT 
  TABLE_NAME, 
  DATA_FREE / 1024 / 1024 AS DATA_FREE_MB,  # 碎片占用空间（MB）
  (DATA_FREE / (DATA_LENGTH + INDEX_LENGTH)) * 100 AS FRAGMENT_RATIO  # 碎片率（%）
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'accounting' 
  AND TABLE_NAME IN ('account_record', 'account_transaction', 'budget_execution');
```

**判断标准**：  
- 若`FRAGMENT_RATIO > 10%`（碎片率超过10%），或`DATA_FREE_MB > 100`（碎片占用超100MB），则需要清理碎片。


#### 2. 执行碎片清理
```bash
# 在MariaDB中执行（针对碎片率高的表）
OPTIMIZE TABLE account_record, account_transaction;

# 清理完成后，再次查看碎片情况，确认碎片率下降
SELECT TABLE_NAME, DATA_FREE / 1024 / 1024 AS DATA_FREE_MB FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'accounting' AND TABLE_NAME IN ('account_record', 'account_transaction');
```

**注意事项**：  
- `OPTIMIZE TABLE`会锁表（InnoDB引擎会重建表），个人使用场景下无并发，可直接执行；  
- 清理时间取决于表大小（10万条记录的表约需1-2分钟），执行期间应用会暂时无法访问该表，建议在非使用时段操作（如凌晨）。


#### 3. 扩展：检查磁盘整体空间（避免磁盘满导致服务崩溃）
每月检查一次磁盘使用率，防止日志/备份文件占满磁盘：
```bash
# 查看磁盘分区使用率（重点关注/分区，即根目录）
df -h

# 查看指定目录（如备份目录）的空间占用
du -sh /opt/accounting/backups/  # 查看备份文件总大小
du -sh /var/lib/mysql/accounting/  # 查看数据库文件大小
```

**处理建议**：  
- 若`/`分区使用率超过80%，删除旧备份文件（保留最近30天）：`find /opt/accounting/backups -name "*.sql" -mtime +30 -delete`；  
- 若日志文件过大（如`/opt/accounting/logs/app.log`），手动截断日志：`echo "" > /opt/accounting/logs/app.log`。


### 二、高级告警（手动检查替代，每月1次）
初期无需配置自动告警（如邮件/短信），通过手动执行“检查脚本”，一次性确认核心服务状态、数据完整性，步骤如下：


#### 1. 编写手动检查脚本（`check_system.sh`）
创建`/opt/accounting/check_system.sh`，包含服务状态、数据库连接、缓存可用性、数据一致性检查：
```bash
#!/bin/bash
# 每月1次手动检查脚本：./check_system.sh

echo "===== 1. 检查核心服务状态 ====="
# 检查MariaDB、Valkey、应用服务状态
services=("mariadb" "valkey" "accounting")
for service in "${services[@]}"; do
  if systemctl is-active --quiet $service; then
    echo "[✓] $service 服务运行正常"
  else
    echo "[×] $service 服务已停止！请执行 sudo systemctl restart $service 重启"
  fi
done

echo -e "\n===== 2. 检查数据库连接 ====="
# 测试数据库连接并查询用户数（确认数据库可用）
mysql -u account_user -p'你的数据库密码' -e "SELECT COUNT(*) AS user_count FROM accounting.sys_user;" > /dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "[✓] 数据库连接正常"
else
  echo "[×] 数据库连接失败！请检查密码或MariaDB服务"
fi

echo -e "\n===== 3. 检查Valkey缓存 ====="
# 测试Valkey连接并执行ping（确认缓存可用）
valkey-cli -a '你的Valkey密码' ping > /dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "[✓] Valkey缓存连接正常"
else
  echo "[×] Valkey连接失败！请检查密码或Valkey服务"
fi

echo -e "\n===== 4. 检查数据一致性（账户余额 vs 余额变动记录） ====="
# 校验账户表余额是否与余额变动表的最新余额一致（避免记账后余额计算错误）
# 1. 获取所有正常状态的账户ID
account_ids=$(mysql -u account_user -p'你的数据库密码' -Nse "SELECT id FROM accounting.account WHERE status=1;")

for account_id in $account_ids; do
  # 2. 账户表当前余额
  account_balance=$(mysql -u account_user -p'你的数据库密码' -Nse "SELECT balance FROM accounting.account WHERE id=$account_id;")
  # 3. 余额变动表的最新余额（未删除记录）
  transaction_balance=$(mysql -u account_user -p'你的数据库密码' -Nse "SELECT balance_after FROM accounting.account_transaction WHERE account_id=$account_id AND is_deleted=0 ORDER BY create_time DESC LIMIT 1;")
  
  # 处理无变动记录的情况（余额应为0）
  if [ -z "$transaction_balance" ]; then
    transaction_balance="0.00"
  fi

  # 比较两个余额是否一致
  if [ "$account_balance" = "$transaction_balance" ]; then
    echo "[✓] 账户ID $account_id 余额一致（账户余额：$account_balance）"
  else
    echo "[×] 账户ID $account_id 余额不一致！账户表：$account_balance，变动表：$transaction_balance"
  fi
done

echo -e "\n===== 5. 检查最近备份是否正常 ====="
# 检查最近7天是否有数据库备份文件
latest_backup=$(find /opt/accounting/backups -name "accounting_*.sql" -mtime -7 | sort -r | head -n 1)
if [ -n "$latest_backup" ]; then
  echo "[✓] 最近7天有备份：$latest_backup"
  # 检查备份文件大小（避免空文件）
  backup_size=$(du -sh "$latest_backup" | awk '{print $1}')
  echo "    备份文件大小：$backup_size"
else
  echo "[×] 最近7天无数据库备份！请执行 ./backup.sh 手动备份"
fi

echo -e "\n===== 检查完成 ====="
```


#### 2. 执行手动检查
每月固定时间（如1号上午）登录ECS，执行脚本：
```bash
# 赋予脚本执行权限（首次执行）
chmod +x /opt/accounting/check_system.sh

# 执行检查
/opt/accounting/check_system.sh
```

**输出示例（正常情况）**：
```
===== 1. 检查核心服务状态 =====
[✓] mariadb 服务运行正常
[✓] valkey 服务运行正常
[✓] accounting 服务运行正常

===== 2. 检查数据库连接 =====
[✓] 数据库连接正常

===== 3. 检查Valkey缓存 =====
[✓] Valkey缓存连接正常

===== 4. 检查数据一致性（账户余额 vs 余额变动记录） =====
[✓] 账户ID 1 余额一致（账户余额：5000.00）
[✓] 账户ID 2 余额一致（账户余额：2000.00）

===== 5. 检查最近备份是否正常 =====
[✓] 最近7天有备份：/opt/accounting/backups/accounting_20240901_020001.sql
    备份文件大小：1.2M

===== 检查完成 =====
```


#### 3. 异常处理指南
若脚本提示异常，按以下优先级处理：
1. **服务停止**：执行 `sudo systemctl restart 服务名`（如`restart accounting`），重启后再次检查；  
2. **数据库/Valkey连接失败**：确认密码是否正确（脚本中的密码是否与配置一致），服务是否正常；  
3. **余额不一致**：优先恢复最近的数据库备份（`mysql -u 用户名 -p 数据库名 < 备份文件.sql`），避免手动修改余额导致更严重的不一致；  
4. **无备份**：立即执行 `./backup.sh` 手动备份，后续检查定时任务是否正常（`crontab -l` 查看备份脚本是否在列）。


### 三、方案优势与注意事项
#### 1. 优势
- **低门槛**：仅依赖Linux基础命令和MariaDB查询，无需学习复杂监控工具；  
- **高可控**：手动执行+可视化输出，问题定位直接，避免自动告警的误报/漏报；  
- **适配个人场景**：每月1次检查频率足够，不占用额外系统资源，维护成本极低。

#### 2. 注意事项
- **密码安全**：脚本中硬编码的数据库/Valkey密码仅用于个人场景，若服务器存在多用户风险，可改为从环境变量读取（`export DB_PASSWORD=xxx`）；  
- **记录检查结果**：建议将每次检查的输出保存到文件（`./check_system.sh > check_20240901.log`），便于后续追溯历史问题；  
- **逐步优化**：若后期觉得手动操作繁琐，可将脚本添加到定时任务（如每月1号凌晨执行，输出到日志文件），实现“半自动化”监控。