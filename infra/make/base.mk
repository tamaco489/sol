# NOTE: Description: Makefile for Terraform
ENV             = stg
VAR_FILE        = ./tfvars/${ENV}.tfvars
VAR_OPTS        = -var-file "$(VAR_FILE)"
BACKEND_FILE    = ./tfbackend/${ENV}.tfbackend
BACKEND_OPTS    = -backend-config="$(BACKEND_FILE)"
TF_BUCKET_NAME  = sol-tfstate


# NOTE: AWS credentials
ifeq ($(ENV), stg)
	export AWS_HOST_NONE_ID=
	export AWS_ACM_ARN=
	export AWS_EC2_INSTANCE_ID=
	export AWS_DB_PASSWORD=password0#
endif

ifeq ($(ENV), prd)
	export AWS_HOST_NONE_ID=
	export AWS_ACM_ARN=
	export AWS_EC2_INSTANCE_ID=
	export AWS_DB_PASSWORD=
endif


# NOTE: Terraform commands
.PHONY: clean fmt init plan apply destroy show lint
clean:
	rm -rf .terraform

fmt:
	terraform fmt

init:
	aws-vault exec miyabiii0310 -- terraform init -reconfigure $(BACKEND_OPTS)

plan:
	aws-vault exec miyabiii0310 -- terraform plan $(VAR_OPTS) -lock=false -refresh=true

apply:
	aws-vault exec miyabiii0310 -- terraform apply $(VAR_OPTS) -lock=false -refresh=true

destroy:
	aws-vault exec miyabiii0310 -- terraform destroy $(VAR_OPTS) -lock=false -refresh=true

show:
	aws-vault exec miyabiii0310 -- terraform show

lint:
	@terraform fmt -check
	@terraform validate
	@tflint --init
	@tflint --recursive

.PHONY: host_zone_import cert_import
host_zone_import:
	aws-vault exec miyabiii0310 -- terraform import aws_route53_zone.sol_host_zone ${AWS_HOST_NONE_ID}

cert_import:
	aws-vault exec miyabiii0310 -- terraform import aws_acm_certificate.cert ${AWS_ACM_ARN}


# NOTE: AWS CLI
.PHONY: create-tfstate-bucket sol-ssm generate-secret force-delete-secret modify-db-password force-delete-cluter
# S3バケット作成、バージョニング有効化
create-tfstate-bucket:
	aws-vault exec miyabiii0310 -- aws s3 mb s3://${ENV}-${TF_BUCKET_NAME}-tfstate
	aws-vault exec miyabiii0310 -- aws s3api put-bucket-versioning --bucket ${ENV}-${TF_BUCKET_NAME}-tfstate --versioning-configuration Status=Enabled

# 踏み台サーバにSSMで接続
sol-ssm:
	aws-vault exec miyabiii0310 -- aws ssm start-session \
	--target ${AWS_EC2_INSTANCE_ID} \
	--region ap-northeast-1

# RDS接続情報をSecrets Managerに保存
generate-secret:
	aws-vault exec miyabiii0310 -- aws secretsmanager create-secret \
	--description "Generate By AWS CLI" \
	--name sol/${ENV}/rds-cluster \
	--secret-string file://../../credential/rds/secret.json \
	--region ap-northeast-1 | jq -r .

# Secrets Managerの強制削除
force-delete-secret:
	aws-vault exec miyabiii0310 -- aws secretsmanager delete-secret \
	--secret-id sol/${ENV}/rds-cluster \
	--force-delete-without-recovery \
	--region ap-northeast-1 | jq -r .

# RDSのパスワード変更
modify-db-password:
	aws-vault exec miyabiii0310 -- aws rds modify-db-cluster \
	--db-cluster-identifier ${ENV}-sol-rds-cluster \
	--master-user-password ${AWS_DB_PASSWORD} | jq -r .

# RDSのクラスター削除
force-delete-cluter:
	aws-vault exec miyabiii0310 -- aws rds delete-db-cluster \
	--db-cluster-identifier ${ENV}-sol-rds-cluster \
	--skip-final-snapshot \
	--region ap-northeast-1 | jq -r .


# NOTE: utilitiy scripts
.PHONY: convert revert convert-for-service revert-for-service
convert:
	bash ../script/util/convert_domain.sh

revert:
	bash ../script/util/revert_domain.sh

convert-for-service:
	bash ../../script/util/convert_domain.sh

revert-for-service:
	bash ../../script/util/revert_domain.sh
