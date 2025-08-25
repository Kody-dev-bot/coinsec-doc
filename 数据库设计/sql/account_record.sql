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
  PRIMARY KEY (`id`),
  KEY `idx_user_date` (`user_id`, `record_date`) COMMENT '按用户+日期查询',
  KEY `idx_account` (`account_id`) COMMENT '按账户查询',
  KEY `idx_category` (`category_id`) COMMENT '按类别查询'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='记账记录表';