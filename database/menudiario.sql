CREATE DATABASE IF NOT EXISTS menudiario
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE menudiario;

CREATE TABLE IF NOT EXISTS md_preferences (
  uid VARCHAR(128) NOT NULL,
  group_id BIGINT UNSIGNED NULL,
  enabled_meals VARCHAR(128) NOT NULL DEFAULT '["lunch"]',
  theme VARCHAR(16) NOT NULL DEFAULT 'system',
  default_reminder_enabled TINYINT(1) NOT NULL DEFAULT 0,
  default_reminder_time VARCHAR(5) NOT NULL DEFAULT '09:00',
  notification_enabled TINYINT(1) NOT NULL DEFAULT 1,
  notification_types VARCHAR(255) NOT NULL DEFAULT '["meal_added","meal_updated","meal_moved","group","reminder"]',
  telegram_user_id VARCHAR(64) NULL,
  telegram_chat_id VARCHAR(64) NULL,
  telegram_username VARCHAR(64) NULL,
  telegram_first_name VARCHAR(120) NULL,
  telegram_linked_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (uid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS md_telegram_link_tokens (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uid VARCHAR(128) NOT NULL,
  token_hash CHAR(64) NOT NULL,
  expires_at DATETIME NOT NULL,
  used_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_md_telegram_token_hash (token_hash),
  KEY idx_md_telegram_token_uid (uid, used_at),
  KEY idx_md_telegram_token_expiry (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS md_telegram_deliveries (
  delivery_key CHAR(64) NOT NULL,
  uid VARCHAR(128) NOT NULL,
  sent_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (delivery_key),
  KEY idx_md_telegram_delivery_uid (uid, sent_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS md_groups (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(120) NOT NULL DEFAULT 'Menu Diario',
  owner_uid VARCHAR(128) NOT NULL,
  invite_code VARCHAR(8) NOT NULL,
  enabled_meals VARCHAR(128) NOT NULL DEFAULT '["lunch"]',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_md_group_invite (invite_code),
  KEY idx_md_group_owner (owner_uid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS md_group_members (
  group_id BIGINT UNSIGNED NOT NULL,
  uid VARCHAR(128) NOT NULL,
  email VARCHAR(255) NOT NULL DEFAULT '',
  joined_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (group_id, uid),
  KEY idx_md_member_uid (uid),
  CONSTRAINT fk_md_member_group FOREIGN KEY (group_id) REFERENCES md_groups(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS md_group_invites (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  group_id BIGINT UNSIGNED NOT NULL,
  email VARCHAR(255) NOT NULL,
  status ENUM('pending', 'accepted', 'cancelled') NOT NULL DEFAULT 'pending',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_md_group_invite_email (group_id, email),
  CONSTRAINT fk_md_invite_group FOREIGN KEY (group_id) REFERENCES md_groups(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS md_daily_options (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  group_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(60) NOT NULL,
  description VARCHAR(180) NOT NULL DEFAULT '',
  active TINYINT(1) NOT NULL DEFAULT 1,
  color VARCHAR(16) NOT NULL DEFAULT 'blue',
  icon VARCHAR(20) NOT NULL DEFAULT 'note',
  display_order INT NOT NULL DEFAULT 0,
  created_by VARCHAR(128) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_md_option_name (group_id, name),
  KEY idx_md_option_group (group_id, active, display_order),
  CONSTRAINT fk_md_option_group FOREIGN KEY (group_id) REFERENCES md_groups(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS md_global_alerts (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  group_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(120) NOT NULL,
  message VARCHAR(240) NOT NULL DEFAULT '',
  alert_time VARCHAR(5) NOT NULL DEFAULT '09:00',
  day_offset TINYINT UNSIGNED NOT NULL DEFAULT 0,
  icon VARCHAR(20) NOT NULL DEFAULT 'bell',
  default_enabled TINYINT(1) NOT NULL DEFAULT 0,
  scope ENUM('all', 'breakfast', 'lunch', 'dinner') NOT NULL DEFAULT 'all',
  active TINYINT(1) NOT NULL DEFAULT 1,
  display_order INT NOT NULL DEFAULT 0,
  created_by VARCHAR(128) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_md_alert_group (group_id, active, display_order),
  CONSTRAINT fk_md_alert_group FOREIGN KEY (group_id) REFERENCES md_groups (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS md_notifications (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  group_id BIGINT UNSIGNED NOT NULL,
  recipient_uid VARCHAR(128) NULL,
  actor_uid VARCHAR(128) NOT NULL,
  actor_name VARCHAR(120) NOT NULL DEFAULT '',
  type VARCHAR(32) NOT NULL,
  message VARCHAR(320) NOT NULL,
  day_date DATE NULL,
  meal_slot ENUM('breakfast', 'lunch', 'dinner') NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_md_notification_group (group_id, created_at),
  KEY idx_md_notification_recipient (recipient_uid, created_at),
  CONSTRAINT fk_md_notification_group FOREIGN KEY (group_id) REFERENCES md_groups (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS md_notification_reads (
  notification_id BIGINT UNSIGNED NOT NULL,
  uid VARCHAR(128) NOT NULL,
  read_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (notification_id, uid),
  KEY idx_md_notification_read_uid (uid),
  CONSTRAINT fk_md_notification_read_notification FOREIGN KEY (notification_id) REFERENCES md_notifications (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS md_dishes (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  owner_uid VARCHAR(128) NOT NULL DEFAULT '*',
  name VARCHAR(190) NOT NULL,
  normalized_name VARCHAR(190) NOT NULL,
  source VARCHAR(32) NOT NULL DEFAULT 'manual',
  archived TINYINT(1) NOT NULL DEFAULT 0,
  times_used INT UNSIGNED NOT NULL DEFAULT 0,
  last_used_at DATETIME NULL,
  created_by VARCHAR(128) NOT NULL DEFAULT '',
  photo_url VARCHAR(512) NOT NULL DEFAULT '',
  photo_file VARCHAR(190) NOT NULL DEFAULT '',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_md_dishes_owner_name (owner_uid, normalized_name),
  KEY idx_md_dishes_owner (owner_uid, archived),
  KEY idx_md_dishes_popularity (owner_uid, times_used)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS md_dish_favorites (
  uid VARCHAR(128) NOT NULL,
  dish_id BIGINT UNSIGNED NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (uid, dish_id),
  KEY idx_md_favorite_dish (dish_id),
  CONSTRAINT fk_md_favorite_dish FOREIGN KEY (dish_id) REFERENCES md_dishes(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS md_week_menus (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  owner_uid VARCHAR(128) NOT NULL,
  title VARCHAR(190) NOT NULL,
  week_start DATE NOT NULL,
  created_by VARCHAR(128) NOT NULL,
  updated_by VARCHAR(128) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_md_week_owner (owner_uid, week_start),
  KEY idx_md_week_start (week_start)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS md_menu_days (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  menu_id BIGINT UNSIGNED NOT NULL,
  day_date DATE NOT NULL,
  skipped TINYINT(1) NOT NULL DEFAULT 0,
  reason VARCHAR(32) NOT NULL DEFAULT '',
  skip_note TEXT NOT NULL,
  notes TEXT NOT NULL,
  option_ids_json TEXT NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_md_day (menu_id, day_date),
  KEY idx_md_day_menu (menu_id),
  CONSTRAINT fk_md_day_menu FOREIGN KEY (menu_id) REFERENCES md_week_menus(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS md_menu_meals (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  menu_day_id BIGINT UNSIGNED NOT NULL,
  meal_slot ENUM('breakfast', 'lunch', 'dinner') NOT NULL,
  items_json TEXT NOT NULL,
  skipped TINYINT(1) NOT NULL DEFAULT 0,
  reason VARCHAR(32) NOT NULL DEFAULT '',
  note TEXT NOT NULL,
  reminder_enabled TINYINT(1) NULL DEFAULT NULL,
  reminder_time VARCHAR(5) NOT NULL DEFAULT '09:00',
  reminder_message VARCHAR(240) NOT NULL DEFAULT '',
  alerts_json TEXT NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_md_meal (menu_day_id, meal_slot),
  CONSTRAINT fk_md_meal_day FOREIGN KEY (menu_day_id) REFERENCES md_menu_days(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS md_telegram_day_shares (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  group_id BIGINT UNSIGNED NOT NULL,
  menu_id BIGINT UNSIGNED NOT NULL,
  day_date DATE NOT NULL,
  token_hash CHAR(64) NOT NULL,
  expires_at DATETIME NOT NULL,
  created_by VARCHAR(128) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_md_telegram_day_share_token (token_hash),
  KEY idx_md_telegram_day_share_expiry (expires_at),
  CONSTRAINT fk_md_telegram_day_share_group FOREIGN KEY (group_id) REFERENCES md_groups(id) ON DELETE CASCADE,
  CONSTRAINT fk_md_telegram_day_share_menu FOREIGN KEY (menu_id) REFERENCES md_week_menus(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT IGNORE INTO md_dishes (owner_uid, name, normalized_name, source, created_by)
VALUES
  ('*', 'Lentejas con verduras', 'lentejas con verduras', 'admin', 'system'),
  ('*', 'Tortilla de patatas', 'tortilla de patatas', 'admin', 'system'),
  ('*', 'Pasta con tomate', 'pasta con tomate', 'admin', 'system'),
  ('*', 'Ensalada completa', 'ensalada completa', 'admin', 'system');
