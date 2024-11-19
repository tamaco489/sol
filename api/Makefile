## 環境変数設定
OAPI_CODEGEN_VERSION=v1.16.2
REDCOLY_VERSION=v1.10.3
SQLC_VERSION=v1.26.0
SQL_MIGRATE=v1.6.1

# NOTE: AWS credentials
ENV = stg
ifeq ($(ENV), stg)
	export AWS_ACCOUNT_ID=
endif

ifeq ($(ENV), prd)
	export AWS_ACCOUNT_ID=
endif


# NOTE: 開発環境の設定
.PHONY: install-tools setup-env dev-build dev-up dev-down dev-logs dev-restart
install-tools:
	go install github.com/deepmap/oapi-codegen/cmd/oapi-codegen@${OAPI_CODEGEN_VERSION}
	go install github.com/sqlc-dev/sqlc/cmd/sqlc@${SQLC_VERSION}
	go install github.com/rubenv/sql-migrate/...@${SQL_MIGRATE}
	npm i -g @redocly/cli@${REDCOLY_VERSION}

setup-env:
	@cp .env_sample .env

dev-build:
	docker compose build --no-cache

dev-up:
	docker compose up -d

dev-down:
	docker compose down

dev-logs:
	docker compose logs -f api

dev-restart:
	docker compose restart api


# NOTE: DBコンテナの操作
.PHONY: mysql test-mysql create-test-db
mysql:
	MYSQL_ROOT_PASSWORD=password#0 docker compose exec mysql mysql -u root -ppassword#0 -h localhost -P 33306 dev

test-mysql:
	MYSQL_ROOT_PASSWORD=password#0 docker compose exec mysql mysql -u root -ppassword#0 -h localhost -P 33306 test

create-test-db:
	docker compose exec -T mysql mysql -uroot -ppassword#0 -e "CREATE DATABASE IF NOT EXISTS test;"
	docker compose exec -T mysql mysql -uroot -ppassword#0 -e "GRANT ALL PRIVILEGES ON test.* TO 'dev'@'%';"
	docker-compose ${COMPOSE_OPTION} exec -T mysql mysql -uroot -ppassword#0 -e "FLUSH PRIVILEGES;"


# NOTE: コード自動生成（API, sqlc）
.PHONY: bundle-openapi generate-api generate-sqlc
generate-api: bundle-openapi
	oapi-codegen -package gen -generate types -o internal/gen/types.gen.go ./spec/openapi.yaml
	oapi-codegen -package gen -generate gin,strict-server -o internal/gen/server.gen.go ./spec/openapi.yaml

bundle-openapi:
	redocly bundle ./spec/openapi_base.yaml --output ./spec/openapi.yaml

generate-sqlc:
	sqlc generate -f internal/db/sqlc.yaml


# NOTE: DBマイグレーション
.PHONY: migrate-new migrate-up migrate-down migrate-status migrate-up-test migrate-down-test
migrate-new:
	docker exec -it sol-db-migrate bash -c "sql-migrate new -env='mysql' $(NAME)"

migrate-up:
	docker exec -it sol-db-migrate ./wrapper.sh up

migrate-down:
	docker exec -it sol-db-migrate ./wrapper.sh down

migrate-up-test:
	ENV="test" bash -x ./build/wrapper.sh up

migrate-down-test:
	ENV="test" ./build/wrapper.sh donw

migrate-status:
	docker exec -it sol-db-migrate ./wrapper.sh status


## NOTE: ローカル実行
.PHONY: deps build run
deps:
	go mod download && go mod tidy

build: deps
	go build -o build/sol_api cmd/main.go

run: build
	./build/sol_api


## NOTE: テスト
.PHONY: test lint
test:
	go test -v -race ./...

lint:
	golangci-lint run --timeout 3m


# NOTE: AWS Lambdaへのデプロイ
VERSION := default

# API
.PHONY: auth
auth:
	aws-vault exec miyabiii0310 -- aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin $(AWS_ACCOUNT_ID).dkr.ecr.ap-northeast-1.amazonaws.com

api-container-build: auth
	docker build --platform linux/amd64 --no-cache -t $(AWS_ACCOUNT_ID).dkr.ecr.ap-northeast-1.amazonaws.com/$(ENV)-sol-api:$(VERSION) -f ./build/Dockerfile .

api-push: api-container-build
	docker tag $(AWS_ACCOUNT_ID).dkr.ecr.ap-northeast-1.amazonaws.com/$(ENV)-sol-api:$(VERSION) $(AWS_ACCOUNT_ID).dkr.ecr.ap-northeast-1.amazonaws.com/$(ENV)-sol-api:latest
	docker push $(AWS_ACCOUNT_ID).dkr.ecr.ap-northeast-1.amazonaws.com/$(ENV)-sol-api:$(VERSION)
	docker push $(AWS_ACCOUNT_ID).dkr.ecr.ap-northeast-1.amazonaws.com/$(ENV)-sol-api:latest

api-deploy: api-push
	aws-vault exec miyabiii0310 -- aws lambda update-function-code \
		--function-name $(ENV)-sol-api \
		--image-uri $(AWS_ACCOUNT_ID).dkr.ecr.ap-northeast-1.amazonaws.com/$(ENV)-sol-api:$(VERSION) | jq .

# DB Migrate
migrate-container-build: auth
	docker build --platform linux/amd64 --no-cache -t $(AWS_ACCOUNT_ID).dkr.ecr.ap-northeast-1.amazonaws.com/$(ENV)-sol-api-migrate:$(VERSION) -f ./build/Dockerfile.migrate .

migrate-push: migrate-container-build
	docker tag $(AWS_ACCOUNT_ID).dkr.ecr.ap-northeast-1.amazonaws.com/$(ENV)-sol-api-migrate:$(VERSION) $(AWS_ACCOUNT_ID).dkr.ecr.ap-northeast-1.amazonaws.com/$(ENV)-sol-api-migrate:latest
	docker push $(AWS_ACCOUNT_ID).dkr.ecr.ap-northeast-1.amazonaws.com/$(ENV)-sol-api-migrate:$(VERSION)
	docker push $(AWS_ACCOUNT_ID).dkr.ecr.ap-northeast-1.amazonaws.com/$(ENV)-sol-api-migrate:latest

migrate-deploy: migrate-push
	aws-vault exec miyabiii0310 -- aws lambda update-function-code \
		--function-name $(ENV)-sol-api-migrate \
		--image-uri $(AWS_ACCOUNT_ID).dkr.ecr.ap-northeast-1.amazonaws.com/$(ENV)-sol-api-migrate:$(VERSION) | jq .

exec-migrate:
	aws-vault exec miyabiii0310 -- aws lambda invoke \
		--function-name $(ENV)-sol-api-migrate \
		--log-type Tail /dev/stdout | jq .
