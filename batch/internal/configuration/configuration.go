package configuration

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/kelseyhightower/envconfig"
)

type Config struct {
	Env         string `envconfig:"ENV" default:"dev"`
	ServiceName string `envconfig:"SERVICE_NAME" default:"sol-file-upload-notifier"`
	DB          struct {
		Host string
		Port string
		User string
		Pass string
		Name string
	}
	AWSConfig aws.Config
}

// DBConfig DB接続情報をSecretsManagerから取得するための構造体
type DBConfig struct {
	DBUser string `json:"username"`
	DBPass string `json:"password"`
	DBHost string `json:"host"`
	DBName string `json:"dbname"`
	DBPort string `json:"port"`
}

var globalConfig Config

func Get() Config { return globalConfig }

func Load(ctx context.Context) (Config, error) {
	envconfig.MustProcess("", &globalConfig)

	ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	// AWSの設定をロードする
	if err := loadAWSConf(ctx, globalConfig.Env); err != nil {
		return globalConfig, fmt.Errorf("failed to load aws config: %w", err)
	}
	if err := loadDBConf(ctx, globalConfig, globalConfig.Env); err != nil {
		return Config{}, err
	}

	return globalConfig, nil
}

func loadDBConf(ctx context.Context, cfg Config, env string) error {
	// DB情報をSSMから取得する
	dbSecretName := fmt.Sprintf("sol/%s/rds-cluster", env) // NOTE: e.g sol/stg/rds-cluster

	dbStr, err := getFromSecretsManager(ctx, cfg.AWSConfig, dbSecretName)
	if err != nil {
		return fmt.Errorf("failed to get db secret: %w", err)
	}
	var dbCfg DBConfig
	if err = json.Unmarshal([]byte(dbStr), &dbCfg); err != nil {
		return fmt.Errorf("failed to parse db secret: %w", err)
	}

	// DB情報をConfigにセットする
	globalConfig.DB.Host = dbCfg.DBHost
	globalConfig.DB.Port = dbCfg.DBPort
	globalConfig.DB.User = dbCfg.DBUser
	globalConfig.DB.Pass = dbCfg.DBPass
	globalConfig.DB.Name = dbCfg.DBName

	return nil
}
