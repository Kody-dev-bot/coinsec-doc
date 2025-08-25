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