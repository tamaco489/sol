#!/bin/bash

awslocal secretsmanager create-secret \
  --name 'sol/dev/rds-cluster' \
  --secret-string '{
    "username":"dev",
    "password":"password",
    "host":"mysql",
    "port":"3306",
    "dbname":"dev"}' \
  --region ap-northeast-1

awslocal secretsmanager create-secret \
  --name 'sol/test/rds-cluster' \
  --secret-string '{
    "username":"dev",
    "password":"password",
    "host":"127.0.0.1",
    "port":"33306",
    "dbname":"test"}' \
  --region ap-northeast-1
