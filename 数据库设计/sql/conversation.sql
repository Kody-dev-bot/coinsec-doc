CREATE TABLE `conversation` (
  `session_id` varchar(64) NOT NULL COMMENT '会话ID',
  `user_id` bigint NOT NULL COMMENT '用户ID',
  `last_record_id` bigint DEFAULT NULL COMMENT '最近记录ID',
  `context_data` text COMMENT '上下文JSON',
  `expire_time` datetime NOT NULL COMMENT '过期时间',
  PRIMARY KEY (`session_id`),
  KEY `idx_user_expire` (`user_id`, `expire_time`) COMMENT '清理过期会话'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='对话上下文表';