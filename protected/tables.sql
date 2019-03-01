SET default_storage_engine=InnoDB;

-- ----------------------------
CREATE TABLE IF NOT EXISTS Salt
(
   id_user INT UNSIGNED NOT NULL PRIMARY KEY,
   salt    CHAR(32)
);

-- --------------------------------------------
CREATE TABLE IF NOT EXISTS Password_Reset_Codes
(
   id_user            INT UNSIGNED,
   code               CHAR(6),
   expires            DATETIME,
   salt               CHAR(32),
   attempts_remaining INT UNSIGNED DEFAULT 3,

   INDEX(id_user)
);

-- ------------------------------------
CREATE TABLE IF NOT EXISTS Session_Info
(
   id_session INT UNSIGNED UNIQUE KEY,

   -- Application-specific session values:
   id_user    INT UNSIGNED,
   id_account INT UNSIGNED,
   handle     VARCHAR(128),

   INDEX(id_session)
);

-- ----------------------------
CREATE TABLE IF NOT EXISTS User
(
   id       INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
   pw_hash  BINARY(16),
   handle   VARCHAR(128) UNIQUE,
   email    VARCHAR(128) UNIQUE,

   INDEX(handle),
   INDEX(email)
);

-- -------------------------------
CREATE TABLE IF NOT EXISTS Account
(
   id     INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
   handle VARCHAR(20) UNIQUE,
   name   VARCHAR(80)
);

