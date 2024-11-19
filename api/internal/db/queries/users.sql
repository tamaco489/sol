-- name: FindUserByAuth0UserID :one
SELECT id FROM users WHERE auth0_user_id = ?;

-- name: InsertUser :execresult
INSERT INTO users (auth0_user_id) VALUES (?);
