-- name: IsProfileExistsByUserID :one
SELECT EXISTS(SELECT 1 FROM profiles WHERE user_id = ?) as is_exists;

-- name: InsertProfile :exec
INSERT INTO profiles (
  user_id,
  first_name,
  last_name,
  first_name_roman,
  last_name_roman,
  birthdate
) VALUES (?, ?, ?, ?, ?, ?);

-- name: FindProfileByUserID :one
SELECT
    id,
    user_id,
    first_name,
    last_name,
    first_name_roman,
    last_name_roman,
    birthdate
FROM profiles
WHERE user_id = ?;
