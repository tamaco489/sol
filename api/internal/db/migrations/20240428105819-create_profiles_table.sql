
-- +migrate Up
CREATE TABLE IF NOT EXISTS `profiles` (
  `id` BIGINT PRIMARY KEY AUTO_INCREMENT,
  `user_id` BIGINT UNIQUE NOT NULL,
  `first_name` VARCHAR(255) NOT NULL,
  `last_name` VARCHAR(255) NOT NULL,
  `first_name_roman` VARCHAR(255) NOT NULL,
  `last_name_roman` VARCHAR(255) NOT NULL,
  `birthdate` DATE NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_user_id` (`user_id`)
);

-- +migrate Down
DROP TABLE IF EXISTS `profiles`;
