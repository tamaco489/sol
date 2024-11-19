package configuration

import (
	"context"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/secretsmanager"

	aws_trace "gopkg.in/DataDog/dd-trace-go.v1/contrib/aws/aws-sdk-go-v2/aws"
)

// 開発時はapiもlocalStackもコンテナで起動するので、localStackのservice名でアクセス
const awsLocalStackDevelopmentURL = "http://localstack:4566"

// テスト時はlocalStackはコンテナで起動するが、テストはホスト側で実行するので、localhostでアクセス
const awsLocalStackTestURL = "http://localhost:4566"

// デフォルトのAWS Region
const awsRegion = "ap-northeast-1"

func loadAWSConf(ctx context.Context, env string) error {
	cfg, err := config.LoadDefaultConfig(ctx, config.WithRegion(awsRegion))
	if err != nil {
		return err
	}
	switch env {
	// ローカル開発環境とテスト環境はlocalstackを利用するためエンドポイントを指定
	// 検証環境と本番環境などでdatadogのトレースを利用する場合はトレースを追加
	// reference: https://docs.localstack.cloud/user-guide/integrations/sdks/go/
	case "dev":
		cfg.BaseEndpoint = aws.String(awsLocalStackDevelopmentURL)
	case "test":
		cfg.BaseEndpoint = aws.String(awsLocalStackTestURL)
	default:
		aws_trace.AppendMiddleware(&cfg, aws_trace.WithServiceName(globalConfig.API.ServiceName))
	}
	globalConfig.AWSConfig = cfg

	return nil
}

// Lambda用のメモリキャッシュ
var awsSecretCache = make(map[string]string)

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
