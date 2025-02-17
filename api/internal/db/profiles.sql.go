// Code generated by sqlc. DO NOT EDIT.
// versions:
//   sqlc v1.25.0
// source: profiles.sql

package db

import (
	"context"
	"time"
)

const findProfileByUserID = `-- name: FindProfileByUserID :one
SELECT
    id,
    user_id,
    first_name,
    last_name,
    first_name_roman,
    last_name_roman,
    birthdate
FROM profiles
WHERE user_id = ?
`

type FindProfileByUserIDRow struct {
	ID             int64
	UserID         int64
	FirstName      string
	LastName       string
	FirstNameRoman string
	LastNameRoman  string
	Birthdate      time.Time
}

func (q *Queries) FindProfileByUserID(ctx context.Context, userID int64) (FindProfileByUserIDRow, error) {
	row := q.db.QueryRowContext(ctx, findProfileByUserID, userID)
	var i FindProfileByUserIDRow
	err := row.Scan(
		&i.ID,
		&i.UserID,
		&i.FirstName,
		&i.LastName,
		&i.FirstNameRoman,
		&i.LastNameRoman,
		&i.Birthdate,
	)
	return i, err
}

const insertProfile = `-- name: InsertProfile :exec
INSERT INTO profiles (
  user_id,
  first_name,
  last_name,
  first_name_roman,
  last_name_roman,
  birthdate
) VALUES (?, ?, ?, ?, ?, ?)
`

type InsertProfileParams struct {
	UserID         int64
	FirstName      string
	LastName       string
	FirstNameRoman string
	LastNameRoman  string
	Birthdate      time.Time
}

func (q *Queries) InsertProfile(ctx context.Context, arg InsertProfileParams) error {
	_, err := q.db.ExecContext(ctx, insertProfile,
		arg.UserID,
		arg.FirstName,
		arg.LastName,
		arg.FirstNameRoman,
		arg.LastNameRoman,
		arg.Birthdate,
	)
	return err
}

const isProfileExistsByUserID = `-- name: IsProfileExistsByUserID :one
SELECT EXISTS(SELECT 1 FROM profiles WHERE user_id = ?) as is_exists
`

func (q *Queries) IsProfileExistsByUserID(ctx context.Context, userID int64) (bool, error) {
	row := q.db.QueryRowContext(ctx, isProfileExistsByUserID, userID)
	var is_exists bool
	err := row.Scan(&is_exists)
	return is_exists, err
}
