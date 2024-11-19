package main

import (
	"context"
	"database/sql"
	"log/slog"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/takeuchima0/sol/batch/internal/configuration"
	"github.com/takeuchima0/sol/batch/internal/utils"

	rdb "github.com/takeuchima0/sol/batch/internal/db"
)

var isDeleted bool

const pathPartsLength int = 3

func handler(ctx context.Context, s3Event events.S3Event) error {
	slog.Info("Start Lambda function.")

	slog.SetDefault(slog.New(slog.NewJSONHandler(os.Stdout, nil)))
	// 環境変数から設定を読み込む
	_, err := configuration.Load(ctx)
	if err != nil {
		slog.Error("Failed to read configuration", err)
	}

	db := rdb.InitDB()
	dbQueries := rdb.New(db)
	defer func(db *sql.DB) {
		if err := db.Close(); err != nil {
			slog.Error("Failed to close DB connection", err)
		}
	}(db)

	for _, r := range s3Event.Records {

		slog.Info("Start Lambda event.", "event_time:", r.EventTime, "bucket_name:", r.S3.Bucket.Name, "object_key:", r.S3.Object.Key)

		// ファイルサイズが0の場合は、S3画像削除、及びDBレコード削除を行うためフラグを立てる
		if r.S3.Object.Size == 0 {
			slog.Info("Object size is Zero.", "object_size:", r.S3.Object.Size)
			isDeleted = true
		}

		pathParts := strings.Split(r.S3.Object.Key, "/")
		if len(pathParts) < pathPartsLength {
			slog.Error("Invalid file path", "path:", r.S3.Object.Key)
			continue
		}

		prefix, userIDStr, _ := pathParts[0], pathParts[1], pathParts[2]
		userID, err := strconv.ParseInt(userIDStr, 10, 64)
		if err != nil {
			slog.Error("Failed to parse user ID", err)
			continue
		}
		slog.Info("Successfully retrieved the prefix and user_id.", "prefix:", prefix, "user_id:", userID)

		switch prefix {
		case "profiles":
			// profiles/<user_id>/<filename>.<extension>の形式でファイルがアップロードされた場合
			if isDeleted {
				if err = handleProfileImageDelete(ctx, dbQueries, userID, r.S3.Object.Key); err != nil {
					slog.Error("Failed to handle profile image delete", err)
					continue
				}
				slog.Info("Successfully deleted S3 images and DB record")
				continue
			}

			// update_atを更新
			if err = handleProfileImageUpdate(ctx, dbQueries, userID, r.EventTime); err != nil {
				slog.Error("Failed to handle profile image update", err)
				continue
			}

			slog.Info("Successfully updated profile_images tables")

		default:
			slog.Error("Unhandled file path prefix", "prefix:", prefix)
			continue
		}
	}

	return nil
}

func handleProfileImageDelete(ctx context.Context, dbQueries *rdb.Queries, userID int64, key string) error {

	slog.Info("Due to invalid object data, S3 image and DB record will be deleted")

	// DBからレコードを削除
	arg := rdb.FindProfileImageByUserIDAndFilePathParams{UserID: userID, FilePath: key}
	row, err := dbQueries.FindProfileImageByUserIDAndFilePath(ctx, arg)
	if err != nil {
		return err
	}

	if err := dbQueries.DeleteProfileImageByID(ctx, row.ID); err != nil {
		return err
	}

	// S3から画像を削除
	if err := utils.DeleteS3Image(ctx, key); err != nil {
		return err
	}

	return nil
}

func handleProfileImageUpdate(ctx context.Context, dbQueries *rdb.Queries, userID int64, eventTime time.Time) error {

	img, err := dbQueries.FindProfileImageUploadFileByUserID(ctx, userID)
	if err != nil {
		return err
	}

	arg := rdb.UpdateProfileImageByIDParams{
		ID:         img,
		UploadedAt: sql.NullTime{Time: eventTime, Valid: true},
	}

	if err = dbQueries.UpdateProfileImageByID(ctx, arg); err != nil {
		return err
	}

	return err
}

func main() {
	lambda.Start(handler)
}
