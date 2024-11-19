package utils

import (
	"context"
	"fmt"
	"log/slog"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/google/uuid"
	"github.com/takeuchima0/sol/internal/configuration"
)

func GenerateFilePath(prefix string, userID int64, ext string) string {
	return fmt.Sprintf("%s/%d/%s.%s", prefix, userID, uuid.New().String(), ext)
}

func GetDownloadPresignedURL(ctx context.Context, filePath string) (url string, err error) {
	input := &s3.GetObjectInput{
		Bucket: aws.String(fmt.Sprintf("%s-sol-image", configuration.Get().API.Env)), // NOTE: e.g dev-sol-image
		Key:    aws.String(filePath),
	}
	s3Client := s3.NewFromConfig(configuration.Get().AWSConfig)
	presignClient := s3.NewPresignClient(s3Client)
	getReq, err := presignClient.PresignGetObject(ctx, input, func(opts *s3.PresignOptions) {
		opts.Expires = time.Duration(1800 * int64(time.Second))
	})
	if err != nil {
		return "", err
	}
	return getReq.URL, nil
}

func GetUploadPresignedURL(ctx context.Context, filePath string) (url string, err error) {
	input := &s3.PutObjectInput{
		Bucket: aws.String(fmt.Sprintf("%s-sol-image", configuration.Get().API.Env)), // NOTE: e.g dev-sol-image
		Key:    aws.String(filePath),
	}

	s3Client := s3.NewFromConfig(configuration.Get().AWSConfig)
	presignClient := s3.NewPresignClient(s3Client)
	putReq, err := presignClient.PresignPutObject(ctx, input, func(opts *s3.PresignOptions) {
		opts.Expires = time.Duration(1800 * int64(time.Second))
	})
	if err != nil {
		return "", err
	}
	return putReq.URL, nil
}

func DeleteProfileImage(ctx context.Context, filePath string) error {
	var svc *s3.Client
	if configuration.Get().API.Env == "dev" || configuration.Get().API.Env == "test" {
		svc = s3.NewFromConfig(configuration.Get().AWSConfig, func(o *s3.Options) {
			o.UsePathStyle = true
		})
	} else {
		svc = s3.NewFromConfig(configuration.Get().AWSConfig)
	}
	slog.Info("awsconfig", "awsconfig", configuration.Get().AWSConfig.BaseEndpoint)
	input := &s3.DeleteObjectInput{
		Bucket: aws.String(fmt.Sprintf("%s-sol-image", configuration.Get().API.Env)), // NOTE: e.g dev-sol-image
		Key:    aws.String(filePath),
	}
	_, err := svc.DeleteObject(ctx, input)
	if err != nil {
		slog.Error(err.Error())
		return err
	}
	return nil
}
