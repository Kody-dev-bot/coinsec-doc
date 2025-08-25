### 一、核心思路
1. **版本管理**：用“版本号+日期”命名jar包（如`accounting-v1.0-20240901.jar`），避免覆盖旧版本，便于追溯。  
2. **自动化更新**：通过脚本完成“备份旧版本→部署新版本→重启服务”全流程，减少手动操作失误。  
3. **快速回滚**：保留最近5个版本的jar包和数据库备份，回滚时仅需“替换jar包→执行回滚SQL（若有）→重启服务”。  


### 二、版本更新流程（自动化脚本）
#### 1. 版本号规范
采用“主版本号.次版本号”+“日期”的命名规则，例如：  
- 初始版本：`accounting-v1.0-20240901.jar`  
- 功能更新：`accounting-v1.1-20240915.jar`  
-  bug修复：`accounting-v1.1.1-20240916.jar`  


#### 2. 编写更新脚本（`deploy.sh`）
创建`/opt/accounting/deploy.sh`，实现“备份旧版本→上传新版本→重启服务”的自动化：
[deploy.sh](scripts/deploy.sh)


#### 3. 执行更新步骤
1. **本地准备**：在Arch Linux开发环境中打包新版本jar（如`accounting-v1.1-20240915.jar`），通过`scp`上传到ECS的`/opt/accounting`目录：  
   ```bash
   # 本地执行：上传新版本jar包到服务器
   scp target/accounting-v1.1-20240915.jar root@你的ECSIP:/opt/accounting/
   ```

2. **服务器执行更新**：  
   ```bash
   # 登录ECS，执行更新脚本
   cd /opt/accounting
   chmod +x deploy.sh
   ./deploy.sh accounting-v1.1-20240915.jar
   ```

3. **验证更新**：  
   - 访问接口（如`curl http://127.0.0.1:8080/api/health`）确认服务正常；  
   - 检查关键功能（如新增记账记录、查看预算）是否正常工作。  


### 三、版本回滚流程（快速恢复）
当新版本出现问题（如记账后余额计算错误、接口报错），通过以下步骤回滚到上一个稳定版本：

#### 1. 编写回滚脚本（`rollback.sh`）
创建`/opt/accounting/rollback.sh`，指定回滚到某个历史版本：
[rollback.sh](scripts/rollback.sh)


#### 2. 执行回滚步骤
1. **查看历史版本**：  
   ```bash
   # 列出备份的历史jar包
   ls -lt /opt/accounting/backups/*.backup-*
   # 输出示例：
   # -rw-r--r-- 1 root root 123456 9月  1 10:00 /opt/accounting/backups/accounting-v1.0.jar.backup-202409011000
   ```

2. **执行回滚**：  
   ```bash
   cd /opt/accounting
   chmod +x rollback.sh
   ./rollback.sh ./backups/accounting-v1.0.jar.backup-202409011000
   ```

3. **关键提示**：  
   - 若新版本通过Flyway执行过数据库脚本（如`V2__add_column.sql`），回滚时需手动执行“反向SQL”（如`ALTER TABLE ... DROP COLUMN`），或直接恢复更新前的数据库备份（脚本中已提示）。  
   - 回滚后务必验证核心功能（如余额计算、预算统计），确保数据一致性。  


### 四、配套配置（确保脚本可用）
#### 1. systemd服务配置（`accounting.service`）
确保服务启动时引用“软链接`current.jar`”，而非固定jar包名，方便更新/回滚时切换版本：  
```ini
# /etc/systemd/system/accounting.service
[Unit]
Description=Accounting Service
After=mariadb.service valkey.service

[Service]
User=root
WorkingDirectory=/opt/accounting
ExecStart=/usr/bin/java -Xms512m -Xmx512m -jar /opt/accounting/current.jar --spring.profiles.active=prod
SuccessExitStatus=143
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```
- 启用服务：`sudo systemctl enable accounting.service`  


#### 2. 版本管理注意事项
- **保留版本数量**：通过脚本中的`MAX_BACKUP=5`控制，避免备份文件占用过多磁盘空间（每个jar包约10-50MB，5个版本仅需250MB以内）。  
- **数据库备份**：更新前的数据库备份是“最后一道防线”，即使jar包回滚失败，也能通过数据库备份恢复到更新前的状态。  
- **本地测试**：新版本在部署到ECS前，务必在Arch Linux开发环境中测试（包括Flyway脚本执行、功能验证），减少线上回滚概率。  


### 五、方案优势
1. **简单易操作**：全流程通过脚本实现，无需记忆复杂命令，适合个人维护。  
2. **安全可靠**：更新前自动备份jar包和数据库，回滚时有完整的恢复依据。  
3. **轻量无依赖**：不依赖额外工具，仅用Linux基础命令和systemd，资源占用可忽略。  