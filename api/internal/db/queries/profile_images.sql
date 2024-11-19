-- name: FindProfileImageByUserID :one
SELECT
  id,
  user_id,
  file_path,
  uploaded_at
FROM
  profile_images
WHERE user_id = ?;

-- name: IsProfileImageExistsByUserID :one
SELECT EXISTS(SELECT 1 FROM profile_images WHERE user_id = ?) as is_exists;

-- name: InsertProfileImage :exec
INSERT INTO profile_images (
  user_id,
  file_path
) VALUES (?, ?);

-- name: DeleteProfileImageByUserID :exec
DELETE FROM profile_images WHERE user_id = ?;
