CREATE TABLE `account_transaction` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `account_id` bigint NOT NULL COMMENT '账户ID',
  `record_id` bigint NOT NULL COMMENT '记账记录ID',
  `amount` decimal(12,2) NOT NULL COMMENT '变动金额（+增加，-减少）',
  `balance_before` decimal(12,2) NOT NULL COMMENT '变动前余额',
  `balance_after` decimal(12,2) NOT NULL COMMENT '变动后余额',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_deleted` tinyint NOT NULL DEFAULT 0 COMMENT '0=未删除,1=已删除',
  `deleted_time` datetime DEFAULT NULL COMMENT '删除时间',
  PRIMARY KEY (`id`),
  KEY `idx_account` (`account_id`) COMMENT '按账户查询',
  KEY `idx_record_deleted` (`record_id`, `is_deleted`) COMMENT '按记录ID+删除状态查询'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='账户余额变动表';