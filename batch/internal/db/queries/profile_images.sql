-- name: FindProfileImageUploadFileByUserID :one
SELECT id FROM profile_images WHERE user_id = ?;

-- name: UpdateProfileImageByID :exec
UPDATE profile_images SET
  uploaded_at = ?
WHERE id = ?;

-- name: FindProfileImageByUserIDAndFilePath :one
SELECT
  id,
  user_id,
  file_path,
  uploaded_at
FROM profile_images
WHERE user_id = ? AND file_path = ?;

-- name: DeleteProfileImageByID :exec
DELETE FROM profile_images WHERE id = ?;
