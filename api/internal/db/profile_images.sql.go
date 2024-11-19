// Code generated by sqlc. DO NOT EDIT.
// versions:
//   sqlc v1.25.0
// source: profile_images.sql

package db

import (
	"context"
	"database/sql"
)

const deleteProfileImageByUserID = `-- name: DeleteProfileImageByUserID :exec
DELETE FROM profile_images WHERE user_id = ?
`

func (q *Queries) DeleteProfileImageByUserID(ctx context.Context, userID int64) error {
	_, err := q.db.ExecContext(ctx, deleteProfileImageByUserID, userID)
	return err
}

const findProfileImageByUserID = `-- name: FindProfileImageByUserID :one
SELECT
  id,
  user_id,
  file_path,
  uploaded_at
FROM
  profile_images
WHERE user_id = ?
`

type FindProfileImageByUserIDRow struct {
	ID         int64
	UserID     int64
	FilePath   string
	UploadedAt sql.NullTime
}

func (q *Queries) FindProfileImageByUserID(ctx context.Context, userID int64) (FindProfileImageByUserIDRow, error) {
	row := q.db.QueryRowContext(ctx, findProfileImageByUserID, userID)
	var i FindProfileImageByUserIDRow
	err := row.Scan(
		&i.ID,
		&i.UserID,
		&i.FilePath,
		&i.UploadedAt,
	)
	return i, err
}

const insertProfileImage = `-- name: InsertProfileImage :exec
INSERT INTO profile_images (
  user_id,
  file_path
) VALUES (?, ?)
`

type InsertProfileImageParams struct {
	UserID   int64
	FilePath string
}

func (q *Queries) InsertProfileImage(ctx context.Context, arg InsertProfileImageParams) error {
	_, err := q.db.ExecContext(ctx, insertProfileImage, arg.UserID, arg.FilePath)
	return err
}

const isProfileImageExistsByUserID = `-- name: IsProfileImageExistsByUserID :one
SELECT EXISTS(SELECT 1 FROM profile_images WHERE user_id = ?) as is_exists
`

func (q *Queries) IsProfileImageExistsByUserID(ctx context.Context, userID int64) (bool, error) {
	row := q.db.QueryRowContext(ctx, isProfileImageExistsByUserID, userID)
	var is_exists bool
	err := row.Scan(&is_exists)
	return is_exists, err
}
