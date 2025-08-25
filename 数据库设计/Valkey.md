### 一、Valkey密码配置（防止恶意访问）
即使已通过安全组限制“仅本机访问”，添加密码仍能进一步提升安全性（例如防止服务器被入侵后直接操作Valkey）。

#### 1. 编辑Valkey配置文件
Valkey的主配置文件通常位于 `/etc/valkey/valkey.conf`（不同系统路径可能不同，可通过`find / -name valkey.conf`查找）。

```bash
# 编辑配置文件
sudo vim /etc/valkey/valkey.conf
```

#### 2. 配置密码
在文件中搜索 `requirepass` 关键字（默认被注释），取消注释并设置密码：
```conf
# 取消注释并设置你的密码（建议包含大小写字母+数字+特殊符号）
requirepass YourStrongPassword123!
```

#### 3. 重启Valkey使配置生效
```bash
# 重启Valkey服务
sudo systemctl restart valkey

# 验证服务状态（确保启动成功）
sudo systemctl status valkey
```

#### 4. 验证密码是否生效
```bash
# 尝试无密码连接（应失败）
valkey-cli
127.0.0.1:6379> ping  # 执行任何命令，应返回(error) NOAUTH Authentication required.

# 使用密码连接（应成功）
valkey-cli -a YourStrongPassword123!
127.0.0.1:6379> ping  # 返回PONG，说明认证成功
```


### 二、Valkey持久化配置（避免缓存丢失）
个人记账场景下，推荐使用 **RDB持久化**（定时快照），兼顾性能和数据安全性（无需实时持久化，每小时备份一次即可）。

#### 1. 配置RDB持久化（定时生成快照）
继续编辑 `valkey.conf`，找到RDB相关配置：
```conf
# 持久化文件存储路径（默认是当前目录，建议指定绝对路径）
dir /var/lib/valkey/

# 持久化文件名（默认即可）
dbfilename dump.rdb

# 快照触发规则：以下三个规则满足其一即生成快照
# 格式：save <seconds> <changes> （多少秒内发生多少修改则触发）
# 个人场景建议调整为：1小时内有1次修改即保存（降低频率，减少IO）
save 3600 1    # 3600秒（1小时）内有1次修改
save 300 10    # 保留默认：5分钟内10次修改（可选，作为补充）
save 60 10000  # 保留默认：1分钟内10000次修改（对个人场景意义不大）
```

#### 2. （可选）配置AOF持久化（实时日志，适合数据敏感场景）
如果希望缓存数据（如会话、临时计算结果）几乎不丢失，可开启AOF（Append Only File）：
```conf
# 启用AOF
appendonly yes

# AOF文件名
appendfilename "appendonly.aof"

# AOF刷新策略（个人场景推荐everysec，平衡性能和安全性）
# everysec：每秒刷新到磁盘（最多丢失1秒数据）
appendfsync everysec
```

#### 3. 重启Valkey并验证持久化
```bash
# 重启服务
sudo systemctl restart valkey

# 验证持久化配置是否生效
valkey-cli -a YourStrongPassword123! config get save  # 查看RDB配置
valkey-cli -a YourStrongPassword123! config get appendonly  # 查看AOF配置（若启用）

# 手动触发一次RDB快照，验证文件生成
valkey-cli -a YourStrongPassword123! save
ls -l /var/lib/valkey/dump.rdb  # 应看到文件已生成
```


### 三、应用配置适配（Spring Boot连接带密码的Valkey）
在Spring Boot项目中，需修改配置文件，添加Valkey密码：

#### 1. 修改`application-prod.yml`
```yaml
spring:
  redis:
    host: localhost
    port: 6379
    password: YourStrongPassword123!  # 新增密码配置
    timeout: 2000ms  # 连接超时时间
    lettuce:
      pool:
        max-active: 8
        max-idle: 8
```

#### 2. 验证应用连接
启动应用后，查看日志是否有 `RedisConnectionFailureException`，若无则说明密码配置正确。


### 四、持久化文件备份（双重保障）
为防止服务器磁盘损坏导致持久化文件丢失，建议定期备份RDB/AOF文件到安全位置（如阿里云OSS或本地电脑）。

#### 1. 编写备份脚本（`valkey_backup.sh`）
```bash
#!/bin/bash
# Valkey持久化文件备份脚本

# 配置
VALKEY_DATA_DIR="/var/lib/valkey"
BACKUP_DIR="/opt/accounting/backups/valkey"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# 创建备份目录
mkdir -p $BACKUP_DIR

# 备份RDB文件（若存在）
if [ -f "${VALKEY_DATA_DIR}/dump.rdb" ]; then
  cp ${VALKEY_DATA_DIR}/dump.rdb ${BACKUP_DIR}/dump.rdb.${TIMESTAMP}
  echo "已备份RDB文件：${BACKUP_DIR}/dump.rdb.${TIMESTAMP}"
fi

# 备份AOF文件（若启用并存在）
if [ -f "${VALKEY_DATA_DIR}/appendonly.aof" ]; then
  cp ${VALKEY_DATA_DIR}/appendonly.aof ${BACKUP_DIR}/appendonly.aof.${TIMESTAMP}
  echo "已备份AOF文件：${BACKUP_DIR}/appendonly.aof.${TIMESTAMP}"
fi

# 保留最近30天的备份
find $BACKUP_DIR -type f -mtime +30 -delete
```

#### 2. 添加到定时任务（每天凌晨3点执行）
```bash
# 编辑定时任务
crontab -e

# 加入以下内容
0 3 * * * /opt/accounting/valkey_backup.sh
```


### 五、总结
1. **密码配置**：通过`requirepass`设置密码，Spring Boot应用同步配置，防止未授权访问。  
2. **持久化方案**：  
   - 推荐RDB（每小时快照），适合个人场景，性能影响小；  
   - 若数据敏感（如缓存的余额数据），可开启AOF（每秒刷新）。  
3. **备份策略**：定时备份持久化文件，防止磁盘故障导致数据丢失。  