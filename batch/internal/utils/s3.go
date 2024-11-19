package utils

import (
	"context"
	"fmt"
	"log/slog"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/takeuchima0/sol/batch/internal/configuration"
)

func DeleteS3Image(ctx context.Context, filePath string) error {
	var svc *s3.Client
	if configuration.Get().Env == "dev" || configuration.Get().Env == "test" {
		svc = s3.NewFromConfig(configuration.Get().AWSConfig, func(o *s3.Options) {
			o.UsePathStyle = true
		})
	} else {
		svc = s3.NewFromConfig(configuration.Get().AWSConfig)
	}

	input := &s3.DeleteObjectInput{
		Bucket: aws.String(fmt.Sprintf("%s-sol-image", configuration.Get().Env)), // NOTE: e.g stg-sol-image
		Key:    aws.String(filePath),
	}
	if _, err := svc.DeleteObject(ctx, input); err != nil {
		slog.Error("[ERROR]", "S3 Delete Object Error.", err)
		return err
	}
	return nil
}
