-- This script contains procedures that will be loaded
-- after the default procedures are loaded.
--
-- The purpose of this file is to intercept the setup
-- process between loading the default, generated .sql
-- scripts containing application procedures, and the
-- procedures in this file that add to or replace those
-- procedures.

DELIMITER $$

-- ----------------------------------------------
DROP FUNCTION IF EXISTS App_User_Confirm_Password $$
CREATE FUNCTION App_User_Confirm_Password(user_id INT UNSIGNED,
                                          pword VARCHAR(40))
RETURNS BOOLEAN
BEGIN
   DECLARE u_hash BINARY(16);
   DECLARE s_salt CHAR(32);

   SELECT u.pw_hash, s.salt INTO u_hash, s_salt
     FROM User u
          INNER JOIN Salt s ON s.id_user = u.id
    WHERE u.id = user_id;

    RETURN u_hash IS NOT NULL
           AND s_salt IS NOT NULL
           AND ssys_confirm_salted_hash(u_hash, s_salt, pword);
END $$

-- This procedure should only be used after a user has been
-- confirmed.
-- -----------------------------------------------------------
DROP PROCEDURE IF EXISTS App_User_Confirmed_Password_Change $$
CREATE PROCEDURE App_User_Confirmed_Password_Change(user_id INT UNSIGNED,
                                                    salt CHAR(32),
                                                    pword VARCHAR(40))
BEGIN
   UPDATE User u
          INNER JOIN Salt s ON s.id_user = u.id
      SET s.salt = salt,
          u.pw_hash = ssys_hash_password_with_salt(pword, salt)
    WHERE u.id = user_id;
END $$

-- -------------------------------------------------------
DROP PROCEDURE IF EXISTS App_User_Coded_Password_Change $$
CREATE PROCEDURE App_User_Coded_Password_Change(user_id INT UNSIGNED,
                                                code CHAR(6),
                                                pword1 VARCHAR(40),
                                                pword2 VARCHAR(40))
proc_block: BEGIN
   DECLARE t_expires DATETIME;
   DECLARE t_salt CHAR(32);
   DECLARE t_code CHAR(6);
   DECLARE t_attempts_remaining INT UNSIGNED;

   -- Early exit for mismatch to avoid attempts penalty.
   -- Notify and leave if two passwords don't match
   IF STRCMP(pword1, pword2) THEN
      SELECT 1 AS error, 'Mismatched Passwords' AS msg;
      LEAVE proc_block;
   END IF;

   SELECT code, expires, salt, attempts_remaining
     INTO t_code, t_expires, t_salt, t_attempts_remaining
     FROM Password_Reset_Codes
    WHERE `id_user` = user_id;

   -- If no code record or code record expired:
   IF t_expires IS NULL OR t_expires < NOW() THEN
      SELECT 1 AS error, 'Password change code expired.' AS msg;

      IF t_expires > NOW() THEN
         DELETE
           FROM Password_Reset_Codes
          WHERE STRCMP(`code`, code) = 0
            AND `id_user` = user_id;
      END IF;

      LEAVE proc_block;
   END IF;

   -- If code mismatched for given user.
   IF STRCMP(t_code, code) THEN
      -- Update code record and notify user, then leave procedure
      IF t_attempts_remaining = 0 THEN
         DELETE
           FROM Password_Reset_Codes
          WHERE STRCMP(`code`, code) = 0
            AND `id_user` = user_id;

         SELECT 1 AS error, 'Too many attempts with this code.' AS msg;
      ELSE
         UPDATE Password_Reset_Codes
            SET attempts_remaining = t_attempts_remaining-1
          WHERE `id_user` = user_id;

         SELECT 1 AS error,
                CONCAT('Mismatched code value, ',
                       t_attempts_remaining,
                       ' attempts remaining.') AS msg;
      END IF;

      LEAVE proc_block;
   END IF;

   -- If we haven't yet left, change the password and signal success
   CALL App_User_Confirmed_Password_Change(user_id, t_salt, pword1);
   SELECT 0 AS error, "Success" AS msg;
END $$

-- ------------------------------------------------------
DROP PROCEDURE IF EXISTS App_User_Create_Password_Code $$
CREATE PROCEDURE App_User_Create_Password_Code(user_id INT UNSIGNED)
BEGIN
   -- IMPORTANT NOTE:
   -- Use session variables to confirm authority to create this code.
   DECLARE t_salt CHAR(32);
   DECLARE t_code CHAR(6);

   SET t_code = SUBSTRING(CONCAT(1000000+ROUND(RAND()*1000000)),2);

   -- Confirm dropped salt before making any changes:
   IF @dropped_salt IS NOT NULL THEN
      SET t_salt = @dropped_salt;
      SET @dropped_salt = NULL;
   ELSE
      -- Fatal error, use non-recoverable termination
      SIGNAL SQLSTATE '45000'
             SET MESSAGE_TEXT='Missing drop-salt instruction.';
   END IF;

   -- Delete any existing reset code for this user:
   DELETE
     FROM Password_Reset_Codes
    WHERE `id_user` = user_id;

   INSERT
     INTO Password_Reset_Codes
          (id_user, code, expires, salt, attempts_remaining)
   VALUES (user_id,
           t_code,
           ADDTIME(NOW(), '00:05:00'),
           t_salt,
           5);

   SELECT t_code;
END $$

-- --------------------------------------------------------------
DROP PROCEDURE IF EXISTS App_User_Create $$
CREATE PROCEDURE App_User_Create(handle VARCHAR(128),
                                 email VARCHAR(128),
                                 pword1 VARCHAR(40),
                                 pword2 VARCHAR(40),
                                 newid INT UNSIGNED)
proc_block: BEGIN
   DECLARE rcount INT UNSIGNED;

   SET newid = NULL;

   -- Check early termination conditions:
   IF @dropped_salt IS NULL THEN
      -- Fatal error, use non-recoverable termination
      SIGNAL SQLSTATE '45000'
             SET MESSAGE_TEXT='Missing drop-salt instruction.';
   END IF;

   IF STRCMP(pword1, pword2) THEN
      -- Query to populate the standard form-result variables
      SELECT 1 AS error, 'Mismatched Passwords' AS msg;
      LEAVE proc_block;
   END IF;

   -- Application-specific code:

   -- Use transaction because rows are created in both Salt and User
   START TRANSACTION;

   INSERT INTO User (pw_hash,
                     handle,
                     email)
             VALUES (ssys_hash_password_with_salt(pword1, @dropped_salt),
                     handle,
                     email);

   IF ROW_COUNT() > 0 THEN
      SET newid = LAST_INSERT_ID();
      INSERT INTO Salt (id_user, salt)
           VALUES (newid, @dropped_salt);

      -- Save ROW_COUNT() so commit doesn't change it.(?)
      -- Otherwise, ROW_COUNT() is never > 0.
      SET rcount = ROW_COUNT();

      IF rcount > 0 THEN
         COMMIT;
      ELSE
         SET newid = NULL;
         ROLLBACK;
      END IF;
   ELSE
      ROLLBACK;
   END IF;
END $$

-- ----------------------------------------
DROP PROCEDURE IF EXISTS App_User_Register $$
CREATE PROCEDURE App_User_Register(handle VARCHAR(128),
                                   email VARCHAR(128),
                                   pword1 VARCHAR(40),
                                   pword2 VARCHAR(40))
BEGIN
   DECLARE newid INT UNSIGNED;

   CALL App_User_Create(handle,email,pword1,pword2,newid);

   IF newid IS NULL THEN
      SELECT 1 AS error,
             CONCAT('Failed to create new user account for ''', handle, '''.') AS msg;
   ELSE
      CALL App_Session_Initialize(newid,handle);
      SELECT 0 AS error, 'Success' AS msg;
   END IF;

END $$


-- ---------------------------------------
DROP PROCEDURE IF EXISTS App_User_Login $$
CREATE PROCEDURE App_User_Login(handle VARCHAR(128),
                                password VARCHAR(40))
BEGIN
   DECLARE u_id INT UNSIGNED;

   SELECT u.id INTO u_id
     FROM User u
    WHERE u.handle = handle;

   IF App_User_Confirm_Password(u_id, password) THEN
      CALL App_Session_Initialize(u_id, handle);
      SELECT 0 AS error, 'Success' AS msg;
   ELSE
      SELECT 1 AS error, 'Invalid handle or password.' AS msg;
   END IF;

END $$

-- -------------------------------------------------
DROP PROCEDURE IF EXISTS App_User_Password_Change $$
CREATE PROCEDURE App_User_Password_Change(user_id INT UNSIGNED,
                                          old_pword VARCHAR(40),
                                          new_pword1 VARCHAR(40),
                                          new_pword2 VARCHAR(40))
proc_block: BEGIN
   DECLARE t_salt CHAR(32);

   -- Check early termination conditions:
   IF @dropped_salt IS NOT NULL THEN
      SET t_salt = @dropped_salt;
      SET @dropped_salt = NULL;
   ELSE
      -- Fatal error, use non-recoverable termination
      SIGNAL SQLSTATE '45000'
             SET MESSAGE_TEXT='Missing drop-salt instruction.';
   END IF;

   IF STRCMP(new_pword1, new_pword2) THEN
      SELECT 1 AS error, 'Mismatched Passwords' AS msg;
      LEAVE proc_block;
   END IF;

   IF NOT App_User_Confirm_Password(user_id, old_pword) THEN
      SELECT 1 AS error, 'Invalid Password' AS msg;
      LEAVE proc_block;
   END IF;

   CALL App_User_Confirmed_Password_Change(user_id,
                                           t_salt,
                                           new_pword1);
END $$


-- Replace procedure from User.sql
-- -------------------------------------
DROP PROCEDURE IF EXISTS App_User_Add $$
CREATE PROCEDURE App_User_Add(handle VARCHAR(128),
                              email VARCHAR(128),
                              password1 VARCHAR(20),
                              password2 VARCHAR(20))
BEGIN
   DECLARE newid INT UNSIGNED;

   CALL App_User_Create(handle,email,password1,password2,newid);

   IF newid IS NOT NULL THEN
      CALL App_User_List(newid);
   END IF;

END $$

DELIMITER ;
