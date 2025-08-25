CREATE TABLE `account_transaction` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `account_id` bigint NOT NULL COMMENT '账户ID',
  `record_id` bigint NOT NULL COMMENT '记账记录ID',
  `amount` decimal(12,2) NOT NULL COMMENT '变动金额（+增加，-减少）',
  `balance_before` decimal(12,2) NOT NULL COMMENT '变动前余额',
  `balance_after` decimal(12,2) NOT NULL COMMENT '变动后余额',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_account` (`account_id`) COMMENT '按账户查询',
  KEY `idx_record` (`record_id`) COMMENT '按记账记录查询'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='账户余额变动表';