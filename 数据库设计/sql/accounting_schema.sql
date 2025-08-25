-- 创建数据库
CREATE DATABASE IF NOT EXISTS accounting 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE accounting;

-- 1. 系统用户表
CREATE TABLE `sys_user` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `username` varchar(50) NOT NULL COMMENT '登录名',
  `password` varchar(100) NOT NULL COMMENT 'BCrypt加密后的密码',
  `nickname` varchar(50) NOT NULL COMMENT '昵称',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '1=正常,0=禁用',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_username` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='系统用户表';

-- 2. 消费类别表
CREATE TABLE `category` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` bigint DEFAULT NULL COMMENT '用户ID（null=系统默认）',
  `name` varchar(30) NOT NULL COMMENT '类别名称',
  `parent_id` bigint DEFAULT NULL COMMENT '父类别ID',
  `type` tinyint NOT NULL COMMENT '1=支出,2=收入,3=通用',
  `sort` int NOT NULL DEFAULT 0 COMMENT '排序权重',
  PRIMARY KEY (`id`),
  KEY `idx_user_type` (`user_id`, `type`) COMMENT '按用户+类型查询'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='消费类别表';

-- 3. 账户表
CREATE TABLE `account` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `name` varchar(50) NOT NULL COMMENT '账户名称',
  `type` tinyint NOT NULL COMMENT '1=银行卡,2=微信,3=支付宝,4=现金',
  `card_no` varchar(50) DEFAULT NULL COMMENT '脱敏卡号',
  `balance` decimal(12,2) NOT NULL DEFAULT 0.00 COMMENT '当前余额',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '1=正常,0=停用',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user` (`user_id`) COMMENT '按用户查询账户'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='账户表';

-- 4. 记账记录表（含逻辑删除）
CREATE TABLE `account_record` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `account_id` bigint NOT NULL COMMENT '账户ID',
  `amount` decimal(12,2) NOT NULL COMMENT '金额',
  `type` tinyint NOT NULL COMMENT '1=支出,2=收入',
  `category_id` bigint NOT NULL COMMENT '类别ID',
  `record_date` date NOT NULL COMMENT '业务日期',
  `original_text` varchar(500) NOT NULL COMMENT '用户原始输入',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '0=未删除,1=已删除',
  `deleted_time` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_deleted_date` (`user_id`, `deleted`, `record_date`) COMMENT '按用户+删除状态+日期查询',
  KEY `idx_account` (`account_id`) COMMENT '按账户查询',
  KEY `idx_category` (`category_id`) COMMENT '按类别查询'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='记账记录表';

-- 5. 账户余额变动表（含逻辑删除）
CREATE TABLE `account_transaction` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `account_id` bigint NOT NULL COMMENT '账户ID',
  `record_id` bigint NOT NULL COMMENT '记账记录ID',
  `amount` decimal(12,2) NOT NULL COMMENT '变动金额（+增加，-减少）',
  `balance_before` decimal(12,2) NOT NULL COMMENT '变动前余额',
  `balance_after` decimal(12,2) NOT NULL COMMENT '变动后余额',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `deleted` tinyint NOT NULL DEFAULT 0 COMMENT '0=未删除,1=已删除',
  `deleted_time` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`),
  KEY `idx_account` (`account_id`) COMMENT '按账户查询',
  KEY `idx_record_deleted` (`record_id`, `deleted`) COMMENT '按记录ID+删除状态查询'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='账户余额变动表';

-- 6. 对话上下文表
CREATE TABLE `conversation` (
  `session_id` varchar(64) NOT NULL COMMENT '会话ID',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `last_record_id` bigint DEFAULT NULL COMMENT '最近记录ID',
  `context_data` text COMMENT '上下文JSON',
  `expire_time` datetime NOT NULL COMMENT '过期时间',
  PRIMARY KEY (`session_id`),
  KEY `idx_user_expire` (`user_id`, `expire_time`) COMMENT '清理过期会话'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='对话上下文表';

-- 7. 系统配置表
CREATE TABLE `sys_config` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `config_key` varchar(50) NOT NULL COMMENT '配置键',
  `config_value` varchar(200) NOT NULL COMMENT '配置值',
  `remark` varchar(200) DEFAULT NULL COMMENT '备注',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_config_key` (`config_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='系统配置表';

-- 8. 预算主表
CREATE TABLE `budget_main` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `cycle_type` tinyint NOT NULL COMMENT '1=月度,2=季度,3=年度',
  `total_amount` decimal(12,2) NOT NULL COMMENT '周期总预算',
  `start_date` date NOT NULL COMMENT '周期开始日期',
  `end_date` date NOT NULL COMMENT '周期结束日期',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '1=启用,0=禁用',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_cycle` (`user_id`, `cycle_type`, `start_date`) COMMENT '用户同周期唯一总预算'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='预算主表（周期总预算）';

-- 9. 预算子表
CREATE TABLE `budget_sub` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `main_id` bigint NOT NULL COMMENT '主预算ID',
  `category_id` bigint NOT NULL COMMENT '消费类别ID',
  `amount` decimal(12,2) NOT NULL COMMENT '子预算金额',
  `remind_ratio` decimal(3,2) NOT NULL DEFAULT 0.8 COMMENT '提醒比例',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_main_category` (`main_id`, `category_id`) COMMENT '同一主预算下类别唯一'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='预算子表（类别拆分）';

-- 10. 预算执行表
CREATE TABLE `budget_execution` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `sub_id` bigint NOT NULL COMMENT '子预算ID',
  `main_id` bigint NOT NULL COMMENT '主预算ID',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `used_amount` decimal(12,2) NOT NULL DEFAULT 0.00 COMMENT '已使用金额',
  `remaining_amount` decimal(12,2) NOT NULL COMMENT '剩余金额',
  `progress_ratio` decimal(5,4) NOT NULL DEFAULT 0.0000 COMMENT '进度比例',
  `is_overspent` tinyint NOT NULL DEFAULT 0 COMMENT '0=未超支,1=超支',
  `last_update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_sub` (`sub_id`) COMMENT '一个子预算对应一条执行记录'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='预算执行表';

-- 初始化系统默认类别
INSERT INTO `category` (name, type, sort) VALUES 
('餐饮', 1, 1), ('交通', 1, 2), ('购物', 1, 3),
('住房', 1, 4), ('娱乐', 1, 5), ('医疗', 1, 6),
('工资', 2, 1), ('兼职', 2, 2), ('投资收益', 2, 3),
('其他收入', 2, 4);
