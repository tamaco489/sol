package configuration

import (
	"context"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/secretsmanager"
)

// 開発時はapiもlocalstackもコンテナで起動するので、localstackのservice名でアクセスする
const awsLocalstackDevelopmentURL = "http://localstack:4566"

// テスト時はlocalstackはコンテナで起動するが、テストはホスト側で実行するので、localhostでアクセスする
const awsLocalstackTestURL = "http://localhost:4566"
const awsRegion = "ap-northeast-1"

func loadAWSConf(ctx context.Context, env string) error {
	cfg, err := config.LoadDefaultConfig(ctx, config.WithRegion(awsRegion))
	if err != nil {
		return err
	}
	switch env {
	// ローカル開発環境とテスト環境はlocalstackを利用するため、エンドポイントを指定する。
	// 検証環境と本番環境はdatadogのトレースを利用するため、トレースを追加する。
	// ref: https://docs.localstack.cloud/user-guide/integrations/sdks/go/
	case "dev":
		cfg.BaseEndpoint = aws.String(awsLocalstackDevelopmentURL)
	case "test":
		cfg.BaseEndpoint = aws.String(awsLocalstackTestURL)
	default:
		// 何もしない
	}
	globalConfig.AWSConfig = cfg

	return nil
}

var awsSecretCache = make(map[string]string) // Lambda用のメモリキャッシュ

func getFromSecretsManager(ctx context.Context, awsConfig aws.Config, secretName string) (string, error) {
	c, exists := awsSecretCache[secretName]
	if exists {
		return c, nil
	}

	svc := secretsmanager.NewFromConfig(awsConfig)
	input := &secretsmanager.GetSecretValueInput{
		SecretId: aws.String(secretName),
	}
	result, err := svc.GetSecretValue(ctx, input)
	if err != nil {
		return "", err
	}
	// キャッシュに追加
	awsSecretCache[secretName] = *result.SecretString
	return *result.SecretString, nil
}
