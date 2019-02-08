CREATE TABLE IF NOT EXISTS Item
(
   id     INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
   name   VARCHAR(40)
);

CREATE TABLE IF NOT EXISTS Person
(
   id     INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
   fname  VARCHAR(20),
   lname  VARCHAR(30),
   dob    DATE,
   gender ENUM('female','male', 'other')
);

CREATE TABLE IF NOT EXISTS Salt
(
   id_user INT UNSIGNED NOT NULL PRIMARY KEY,
   salt    CHAR(32)
);

-- Session Information Section (one table)
CREATE TABLE IF NOT EXISTS Session_Info
(
   id_session INT UNSIGNED UNIQUE KEY,

   person_id   INT UNSIGNED,
   person_name VARCHAR(128),

   INDEX(id_session)
);


