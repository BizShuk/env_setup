# MySQL Setup Guide

MySQL is a relational database management system.

## Quick Start

### 1. Start MySQL Container

```bash
cd devops
docker-compose up -d mysql
```

### 2. Connection Details

- **Host**: `localhost` (from host) or `mysql` (from other containers)
- **Port**: `3306`
- **Root Password**: `rootpassword`
- **Default Database**: `defaultDB`

## Accessing MySQL

### From Host (via CLI)

```bash
mysql -h 127.0.0.1 -P 3306 -u root -p
```

### From Docker

```bash
docker exec -it mysql mysql -u root -p
```

## Maintenance

Data is persisted in the `mysql_data` Docker volume.

## References

- [MySQL Documentation](https://dev.mysql.com/doc/)
