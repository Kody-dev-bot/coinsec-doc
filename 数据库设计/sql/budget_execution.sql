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