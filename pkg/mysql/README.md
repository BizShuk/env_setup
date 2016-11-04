# mysql

### TODO
1. how to set in-memory mode
2. keep connection
3. send log by socket to log service
4. 



### configure file
mysqlId.cnf , default in /etc/mysql/mysql.conf.d/


### Command
mysql -u [username] -p --password=[password] -P [port] 


### SQL
Properties:
- username 
- password 
- host , % , localhost , any ip and domain
- db , * , dbname
- dbname 
- permission , insert select delete update create

SQL
- show databases;
- show tables;
- 

SQL admin
- create database [dbname];
- create user '[username]'@'[host]' identified by '[password]';
- grant [permission] on [db].* to '[username]'@'[host]';
- show grants for [username]
- rename user '[username]'@'[host]' to '[username]'@'[host]'
- set password for '[username]'@'[host]' = PASSWORD('[password]')


SQL system info
- show variables like "%version%";
- 