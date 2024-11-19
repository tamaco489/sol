
-- +migrate Up
CREATE TABLE IF NOT EXISTS `profile_images` (
  `id`          BIGINT PRIMARY KEY AUTO_INCREMENT,
  `user_id`     BIGINT UNIQUE NOT NULL,
  `file_path`   CHAR(255) NOT NULL,
  `uploaded_at` DATETIME DEFAULT NULL,
  `created_at`  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT `profile_images_fk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  INDEX `idx_user_id` (`user_id`)
);

-- +migrate Down
DROP TABLE IF EXISTS `profile_images`;
