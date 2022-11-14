---
title: "RDS Setup"
sidebar_position: 60
weight: 60
---

An RDS instance, Aurora RDS, was provisioned as part of the infrastruture setup. The details of the RDS instance are available in the environment variables.

### Load Data

The last step is to create some data in the database. Install psql, standard CLI to interact with PostgreSQL database:

```bash
$ sudo amazon-linux-extras install -y postgresql12
```

Create a table and load some data:

```bash
$ cat << EoF > ~/environment/sg-per-pod/pgsql.sql
CREATE TABLE welcome (column1 TEXT);
insert into welcome values ('--------------------------');
insert into welcome values ('Welcome to the eksworkshop');
insert into welcome values ('--------------------------');
EoF
```

Run the created script:

```bash
$ psql postgresql://eksworkshop:${RDS_PASSWORD}@${RDS_ENDPOINT}:5432/eksworkshop \
    -f ~/environment/sg-per-pod/pgsql.sql
```
