# postgres

### configure

default conf path: under data directory (postgres.conf)

### pg_dump
`pg_dump <dbname> > dbname.sql`
`pg_dumpall > dball.sql`

###  psql 
client tools


- `-U <user>`
- `-h <host>`
- `-c <query>`



interaction mode:
- `\?` , show 
- `\h` , show query syntax
- `\l` , show databases
- `\dt` , show tables
- `\du` , show all users
- `\password <user>` , change password

### Query
- `show data_directory` , show location of postgres
- `show all;` , show run-time parameters
- `show config_file;`



### DB
- `createdb [-T <temp_dbname>] <dbname>` 
    - `-T`, for as a template`
- `dropdb <dbname>`
- `CREATE TABLESPACE <dbname> LOCATION '/path/to/dir';`



### User and Group
- `alter user <user> with encrypted password '<password>'`
- `alter user <user> with [superuser,nosuperuser]`
- `alter user <olduser> rename to <newuser>`
- `drop user <user>`
- `select current_user`
- `create user <usr> password '<password>' in group <group>`


- `alter group <group> [add,drop] user <user>`
















