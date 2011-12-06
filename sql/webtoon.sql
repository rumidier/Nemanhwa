-- ---
-- Table 'site'
-- 
DROP TABLE IF EXISTS site;
CREATE TABLE site (
  id          INTEGER     AUTO_INCREMENT NOT NULL,
  name        VARCHAR(64) DEFAULT NULL,
  start_url   MEDIUMTEXT  DEFAULT NULL,
  webtoon_url MEDIUMTEXT  DEFAULT NULL,

  PRIMARY KEY (id)
);
ALTER TABLE site TYPE = InnoDB;

-- ---
-- Table 'webtoon'
-- 
DROP TABLE IF EXISTS webtoon;
CREATE TABLE webtoon (
  site_id INTEGER      NOT NULL,
  id      INTEGER      AUTO_INCREMENT NOT NULL,
  code    VARCHAR(128) NOT NULL,
  name    VARCHAR(256) DEFAULT NULL,
  image   MEDIUMTEXT   DEFAULT NULL,

  PRIMARY KEY (id),
  FOREIGN KEY (site_id) REFERENCES site(id)
);
ALTER TABLE webtoon TYPE = InnoDB;

-- ---
-- Table 'round'
-- 
DROP TABLE IF EXISTS round;
CREATE TABLE round (
  webtoon_id INTEGER      NOT NULL
  id         INTEGER      AUTO_INCREMENT NOT NULL,
  chapter    MEDIUMTEXT   NOT NULL,
  chapter_id MEDIUMTEXT   NOT NULL,

  PRIMARY KEY (id),
  FOREIGN KEY (webtoon_id) REFERENCES webtoon(id)
);
ALTER TABLE round TYPE = InnoDB;


--
-- Mysql에서는 FOREIGN KEY 를 위해서는
-- ALTER TABLE round TYPE = InnoDB; 구문이 필요하다.
-- FOREIGN KEY
-- FOREIGN KEY (webtoon_id) REFERENCES webtoon(id)
-- 연결되는 자식의 KET는 테이블네임_ID 어미주소는 테이블네임(ID)로 
-- 하는게 유지보수가 좋다
