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