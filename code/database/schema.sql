-- Copyright 2021 Google LLC
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--      http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

CREATE DATABASE IF NOT EXISTS test;

USE test;

DROP TABLE IF EXISTS `test`;

CREATE TABLE `test` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `title` varchar(512) DEFAULT NULL,
  `updated` datetime DEFAULT NULL,
  `completed` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

LOCK TABLES `test` WRITE;
/*!40000 ALTER TABLE `test` DISABLE KEYS */;

INSERT INTO `test` (`id`, `title`, `updated`, `completed`)
VALUES
  (1,'Install and configure test app','2021-10-28 12:00:00','2021-10-28 12:00:00'),
	(2,'Add your own test','2021-10-28 12:00:00',NULL),
	(3,'Mark task 1 done','2021-10-27 14:26:00',NULL);

/*!40000 ALTER TABLE `test` ENABLE KEYS */;
UNLOCK TABLES;

CREATE USER 'test'@'localhost' IDENTIFIED BY 'test';
CREATE USER 'test'@'%' IDENTIFIED BY 'test';

GRANT ALL ON test.* TO 'test_user'@'localhost';
GRANT ALL ON test.* TO 'test_user'@'%';