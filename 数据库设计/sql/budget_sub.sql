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