# NOTE: AWS credentials
ENV = stg
ifeq ($(ENV), stg)
	export AWS_ACCOUNT_ID=
endif

ifeq ($(ENV), prd)
	export AWS_ACCOUNT_ID=
endif


# NOTE: 開発環境の設定
.PHONY: install-tools generate-sqlc lint
install-tools:
	go install github.com/sqlc-dev/sqlc/cmd/sqlc@latest

generate-sqlc:
	sqlc generate -f internal/db/sqlc.yaml

lint:
	golangci-lint run --timeout 3m


# NOTE: AWS Lambdaへのデプロイ
VERSION := default
.PHONY: auth build push
auth:
	aws-vault exec miyabiii0310 -- aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin $(AWS_ACCOUNT_ID).dkr.ecr.ap-northeast-1.amazonaws.com

build: auth
	docker build --platform linux/amd64 --no-cache -t $(AWS_ACCOUNT_ID).dkr.ecr.ap-northeast-1.amazonaws.com/$(ENV)-sol-file-upload-notifier:$(VERSION) -f ./build/Dockerfile.file_upload_notifier .

push: build
	docker tag $(AWS_ACCOUNT_ID).dkr.ecr.ap-northeast-1.amazonaws.com/$(ENV)-sol-file-upload-notifier:$(VERSION) $(AWS_ACCOUNT_ID).dkr.ecr.ap-northeast-1.amazonaws.com/$(ENV)-sol-file-upload-notifier:latest
	docker push $(AWS_ACCOUNT_ID).dkr.ecr.ap-northeast-1.amazonaws.com/$(ENV)-sol-file-upload-notifier:$(VERSION)
	docker push $(AWS_ACCOUNT_ID).dkr.ecr.ap-northeast-1.amazonaws.com/$(ENV)-sol-file-upload-notifier:latest

deploy: push
	aws-vault exec miyabiii0310 -- aws lambda update-function-code \
		--function-name $(ENV)-sol-file-upload-notifier \
		--image-uri $(AWS_ACCOUNT_ID).dkr.ecr.ap-northeast-1.amazonaws.com/$(ENV)-sol-file-upload-notifier:$(VERSION) | jq .

exec:
	aws-vault exec miyabiii0310 -- aws lambda invoke \
		--function-name $(ENV)-sol-file-upload-notifier \
		--log-type Tail /dev/stdout | jq .
