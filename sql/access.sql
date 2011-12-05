
-- ---
-- Globals
-- ---

-- SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";
-- SET FOREIGN_KEY_CHECKS=0;

-- ---
-- Table 'access'
-- 
-- ---

DROP TABLE IF EXISTS `access`;
		
CREATE TABLE `access` (
  `name` VARCHAR(50),
  `site` MEDIUMTEXT DEFAULT NULL,
  `start-url` MEDIUMTEXT DEFAULT NULL,
  `first-url` MEDIUMTEXT DEFAULT NULL,
  `last-url` MEDIUMTEXT DEFAULT NULL,
  PRIMARY KEY (`name`)
);

-- ---
-- Foreign Keys 
-- ---


-- ---
-- Table Properties
-- ---

-- ALTER TABLE `access` ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

-- ---
-- Test Data
-- ---

-- INSERT INTO `access` (`id`,`name`,`site`,`start-url`,`first-url`,`last-url`) VALUES
-- ('','','','','','');

