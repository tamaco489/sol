-- name: IsAddressExistsByUserID :one
SELECT EXISTS(SELECT 1 FROM addresses WHERE user_id = ?) as is_exists;

-- name: InsertAddress :exec
INSERT INTO addresses (
  user_id,
  zip_code,
  prefecture,
  city,
  street
) VALUES (?, ?, ?, ?, ?);

-- name: FindAddressByUserID :one
SELECT
    id,
    user_id,
    zip_code,
    prefecture,
    city,
    street
FROM addresses
WHERE user_id = ?;
