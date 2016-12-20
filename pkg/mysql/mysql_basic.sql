CREATE USER IF NOT EXISTS 'test'@'localhost' IDENTIFIED BY 'zxcvasdf';
GRANT ALL on slURL.* to 'test'@'localhost';
FLUSH PRIVILEGES;