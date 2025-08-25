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