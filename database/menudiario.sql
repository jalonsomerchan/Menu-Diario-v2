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
  breakfast_time VARCHAR(5) NULL DEFAULT NULL,
  lunch_time VARCHAR(5) NULL DEFAULT NULL,
  dinner_time VARCHAR(5) NULL DEFAULT NULL,
  calendar_token VARCHAR(96) NULL,
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
  default_supermarket_id BIGINT UNSIGNED NULL,
  enabled_meals VARCHAR(128) NOT NULL DEFAULT '["lunch"]',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_md_group_invite (invite_code),
  KEY idx_md_group_owner (owner_uid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS md_supermarkets (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  slug VARCHAR(64) NOT NULL,
  name VARCHAR(120) NOT NULL,
  logo VARCHAR(120) NOT NULL DEFAULT '',
  brand_color VARCHAR(16) NOT NULL DEFAULT '#2c6b4c',
  display_order INT NOT NULL DEFAULT 0,
  active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_md_supermarket_slug (slug),
  KEY idx_md_supermarket_active (active, display_order)
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

CREATE TABLE IF NOT EXISTS md_tasks (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  group_id BIGINT UNSIGNED NOT NULL,
  title VARCHAR(190) NOT NULL,
  description TEXT NOT NULL,
  assigned_all TINYINT(1) NOT NULL DEFAULT 1,
  assigned_uid VARCHAR(128) NULL,
  status ENUM('pending', 'parked', 'completed', 'cancelled') NOT NULL DEFAULT 'pending',
  importance ENUM('low', 'medium', 'high') NOT NULL DEFAULT 'medium',
  due_at DATETIME NULL,
  reminders_json TEXT NOT NULL,
  created_by VARCHAR(128) NOT NULL,
  updated_by VARCHAR(128) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_md_task_group_status (group_id, status, due_at),
  KEY idx_md_task_assigned (group_id, assigned_uid),
  CONSTRAINT fk_md_task_group FOREIGN KEY (group_id) REFERENCES md_groups(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS md_task_reminder_deliveries (
  delivery_key CHAR(64) NOT NULL,
  task_id BIGINT UNSIGNED NOT NULL,
  uid VARCHAR(128) NOT NULL,
  triggered_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (delivery_key),
  KEY idx_md_task_delivery_task (task_id, triggered_at),
  CONSTRAINT fk_md_task_delivery_task FOREIGN KEY (task_id) REFERENCES md_tasks(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS md_dishes (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  owner_uid VARCHAR(128) NOT NULL DEFAULT '*',
  name VARCHAR(190) NOT NULL,
  normalized_name VARCHAR(190) NOT NULL,
  source VARCHAR(32) NOT NULL DEFAULT 'manual',
  type VARCHAR(32) NOT NULL DEFAULT 'home',
  category VARCHAR(32) NOT NULL DEFAULT 'other',
  archived TINYINT(1) NOT NULL DEFAULT 0,
  times_used INT UNSIGNED NOT NULL DEFAULT 0,
  last_used_at DATETIME NULL,
  created_by VARCHAR(128) NOT NULL DEFAULT '',
  photo_url VARCHAR(512) NOT NULL DEFAULT '',
  photo_file VARCHAR(190) NOT NULL DEFAULT '',
  description TEXT NOT NULL,
  recipe TEXT NOT NULL,
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

CREATE TABLE IF NOT EXISTS md_dish_ingredients (
  uid VARCHAR(128) NOT NULL,
  dish_id BIGINT UNSIGNED NOT NULL,
  ingredients_json TEXT NOT NULL,
  migrated_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (uid, dish_id),
  KEY idx_md_dish_ingredients_dish (dish_id),
  CONSTRAINT fk_md_dish_ingredients_dish FOREIGN KEY (dish_id) REFERENCES md_dishes(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS md_ingredients (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(190) NOT NULL,
  normalized_name VARCHAR(190) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_md_ingredient_normalized_name (normalized_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS md_user_ingredients (
  uid VARCHAR(128) NOT NULL,
  ingredient_id BIGINT UNSIGNED NOT NULL,
  exclude_from_shopping TINYINT(1) NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (uid, ingredient_id),
  KEY idx_md_user_ingredients_ingredient (ingredient_id),
  CONSTRAINT fk_md_user_ingredients_ingredient FOREIGN KEY (ingredient_id) REFERENCES md_ingredients(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS md_group_ingredients (
  group_id BIGINT UNSIGNED NOT NULL,
  ingredient_id BIGINT UNSIGNED NOT NULL,
  supermarket_id BIGINT UNSIGNED NOT NULL,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (group_id, ingredient_id),
  KEY idx_md_group_ingredients_supermarket (supermarket_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS md_dish_ingredient_links (
  uid VARCHAR(128) NOT NULL,
  dish_id BIGINT UNSIGNED NOT NULL,
  ingredient_id BIGINT UNSIGNED NOT NULL,
  display_order INT UNSIGNED NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (uid, dish_id, ingredient_id),
  KEY idx_md_dish_ingredient_links_dish (uid, dish_id, display_order),
  KEY idx_md_dish_ingredient_links_ingredient (ingredient_id),
  CONSTRAINT fk_md_dish_ingredient_links_dish FOREIGN KEY (dish_id) REFERENCES md_dishes(id) ON DELETE CASCADE,
  CONSTRAINT fk_md_dish_ingredient_links_ingredient FOREIGN KEY (ingredient_id) REFERENCES md_ingredients(id) ON DELETE CASCADE
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

INSERT IGNORE INTO md_supermarkets (slug, name, logo, brand_color, display_order) VALUES
  ('mercadona', 'Mercadona', 'mercadona', '#00843d', 10),
  ('dia', 'DIA', 'dia', '#e30613', 20),
  ('lidl', 'Lidl', 'lidl', '#0050aa', 30),
  ('spar', 'SPAR', 'spar', '#e30613', 40),
  ('costco', 'Costco', 'costco', '#e31837', 50),
  ('hipercor', 'Hipercor', 'hipercor', '#ec1c24', 60),
  ('provecaex', 'Provecaex', 'provecaex', '#166534', 70),
  ('carrefour', 'Carrefour', 'carrefour', '#004e9e', 80),
  ('campesano', 'Campesano', 'campesano', '#8b5e34', 90),
  ('alcampo', 'Alcampo', 'alcampo', '#e30613', 100),
  ('aldi', 'ALDI', 'aldi', '#0066b3', 110),
  ('eroski', 'Eroski', 'eroski', '#e30613', 120),
  ('consum', 'Consum', 'consum', '#e30613', 130),
  ('bm', 'BM Supermercados', 'bm', '#1d4ed8', 140),
  ('el-corte-ingles', 'El Corte Inglés', 'el-corte-ingles', '#007a53', 150),
  ('leclerc', 'E.Leclerc', 'leclerc', '#e30613', 160),
  ('otro', 'Otro supermercado', 'otro', '#64748b', 999);
