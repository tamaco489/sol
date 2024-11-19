package usecase

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/oapi-codegen/runtime/types"
	"github.com/takeuchima0/sol/internal/db"
	"github.com/takeuchima0/sol/internal/gen"
	"github.com/takeuchima0/sol/internal/utils"
)

type ProfileUseCase interface {
	CreateProfile(ctx context.Context, request gen.CreateProfileRequestObject) (gen.CreateProfileResponseObject, error)
	GetProfileImage(ctx context.Context, request gen.GetProfileImageRequestObject) (gen.GetProfileImageResponseObject, error)
	CreateProfileImage(ctx context.Context, request gen.CreateProfileImageRequestObject) (gen.CreateProfileImageResponseObject, error)
	UpdateProfileImage(ctx context.Context, request gen.UpdateProfileImageRequestObject) (gen.UpdateProfileImageResponseObject, error)
	DeleteProfileImage(ctx context.Context, request gen.DeleteProfileImageRequestObject) (gen.DeleteProfileImageResponseObject, error)
}

type profileUseCase struct {
	queries *db.Queries
	db      *sql.DB
}

func NewProfileUseCase(queries *db.Queries, db *sql.DB) ProfileUseCase {
	return &profileUseCase{
		queries: queries,
		db:      db,
	}
}

const zipcodeLength = 7

func (u *profileUseCase) CreateProfile(ctx context.Context, request gen.CreateProfileRequestObject) (gen.CreateProfileResponseObject, error) {

	// TODO: 本来はここでAuth0の認可が済んだuser_idをcontextから取得
	userID := int64(1)

	// リクエストのバリデーション
	if request.Body.Name.FirstName == "" || request.Body.Name.LastName == "" || request.Body.Name.FirstNameRoman == "" || request.Body.Name.LastNameRoman == "" {
		return gen.CreateProfile400Response{}, nil
	}

	trimmedZipCode := strings.Replace(request.Body.Address.ZipCode, "-", "", -1)
	if trimmedZipCode == "" || utf8.RuneCountInString(trimmedZipCode) != zipcodeLength {
		return gen.CreateProfile400Response{}, nil
	}

	if request.Body.Address.Prefecture == "" || request.Body.Address.City == "" {
		return gen.CreateProfile400Response{}, nil
	}

	currentTime := time.Now()
	if request.Body.Birthdate.Time.IsZero() {
		return gen.CreateProfile400Response{}, nil
	}

	if request.Body.Birthdate.Time.After(currentTime) {
		return gen.CreateProfile400Response{}, nil
	}

	var street string
	if request.Body.Address.Street != nil {
		street = *request.Body.Address.Street
	}

	hasProfile, err := u.queries.IsProfileExistsByUserID(ctx, userID)
	if err != nil {
		return gen.CreateProfile500Response{}, err
	}

	hasAddress, err := u.queries.IsAddressExistsByUserID(ctx, userID)
	if err != nil {
		return gen.CreateProfile500Response{}, err
	}

	if hasProfile || hasAddress {
		return gen.CreateProfile409Response{}, nil
	}

	profileArgs := db.InsertProfileParams{
		UserID:         userID,
		FirstName:      request.Body.Name.FirstName,
		LastName:       request.Body.Name.LastName,
		FirstNameRoman: request.Body.Name.FirstNameRoman,
		LastNameRoman:  request.Body.Name.LastNameRoman,
		Birthdate:      request.Body.Birthdate.Time,
	}

	addressArgs := db.InsertAddressParams{
		UserID:     userID,
		ZipCode:    trimmedZipCode,
		Prefecture: request.Body.Address.Prefecture,
		City:       request.Body.Address.City,
		Street:     street,
	}

	// トランザクション開始
	tx, err := u.db.BeginTx(ctx, nil)
	if err != nil {
		return gen.CreateProfile500Response{}, err
	}

	txq := u.queries.WithTx(tx)

	// プロフィールの登録
	if err := txq.InsertProfile(ctx, profileArgs); err != nil {
		if err = tx.Rollback(); err != nil {
			return gen.CreateProfile500Response{}, err
		}
		return gen.CreateProfile500Response{}, err
	}

	// 住所の登録
	if err = txq.InsertAddress(ctx, addressArgs); err != nil {
		if err = tx.Rollback(); err != nil {
			return gen.CreateProfile500Response{}, err
		}
		return gen.CreateProfile500Response{}, err
	}

	// トランザクション終了
	if err = tx.Commit(); err != nil {
		if err := tx.Rollback(); err != nil {
			return gen.CreateProfile500Response{}, err
		}
		return gen.CreateProfile500Response{}, err
	}

	// プロフィールと住所登録後にレコードを取得し、レスポンスの構造体に変換
	profile, err := u.queries.FindProfileByUserID(ctx, userID)
	if err != nil {
		return gen.CreateProfile500Response{}, err
	}

	addr, err := u.queries.FindAddressByUserID(ctx, userID)
	if err != nil {
		return gen.CreateProfile500Response{}, err
	}

	resAddr := struct {
		City       string  `json:"city"`
		Prefecture string  `json:"prefecture"`
		Street     *string `json:"street,omitempty"`
		ZipCode    string  `json:"zip_code"`
	}{
		City:       addr.City,
		Prefecture: addr.Prefecture,
		Street:     &addr.Street,
		ZipCode:    addr.ZipCode,
	}

	resbirth := types.Date{Time: profile.Birthdate}

	resName := struct {
		FirstName      string `json:"first_name"`
		FirstNameRoman string `json:"first_name_roman"`
		LastName       string `json:"last_name"`
		LastNameRoman  string `json:"last_name_roman"`
	}{
		FirstName:      profile.FirstName,
		FirstNameRoman: profile.FirstNameRoman,
		LastName:       profile.LastName,
		LastNameRoman:  profile.LastNameRoman,
	}

	return gen.CreateProfile201JSONResponse{
		Address:   resAddr,
		Birthdate: resbirth,
		Name:      resName,
	}, nil
}

func (u *profileUseCase) GetProfileImage(ctx context.Context, request gen.GetProfileImageRequestObject) (gen.GetProfileImageResponseObject, error) {

	// TODO: 本来はここでAuth0の認可が済んだuser_idをcontextから取得
	userID := int64(1)

	img, err := u.queries.FindProfileImageByUserID(ctx, userID)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return gen.GetProfileImage404Response{}, nil
		}
		return gen.GetProfileImage500Response{}, err
	}

	extension := strings.Split(img.FilePath, ".")[1]

	// uploaded_atがNULLの場合はURLを空文字にして返す
	var url string
	if !img.UploadedAt.Valid {
		return gen.GetProfileImage200JSONResponse{
			Url:       url,
			Extension: extension,
		}, nil
	}

	switch *request.Params.Type {
	case "download":
		url, err = utils.GetDownloadPresignedURL(ctx, img.FilePath)
		if err != nil {
			return gen.GetProfileImage500Response{}, err
		}
	case "upload":
		url, err = utils.GetUploadPresignedURL(ctx, img.FilePath)
		if err != nil {
			return gen.GetProfileImage500Response{}, err
		}
	default:
		return gen.GetProfileImage400Response{}, fmt.Errorf("invalid type: %s", *request.Params.Type)
	}

	return gen.GetProfileImage200JSONResponse{
		Url:       url,
		Extension: extension,
	}, nil
}

func (u *profileUseCase) CreateProfileImage(ctx context.Context, request gen.CreateProfileImageRequestObject) (gen.CreateProfileImageResponseObject, error) {

	// TODO: 本来はここでAuth0の認可が済んだuser_idをcontextから取得
	userID := int64(1)

	// png. jpeg, jpgのみ許可
	switch request.Body.Extension {
	case "png", "jpeg", "jpg":
		break
	default:
		return gen.CreateProfileImage400Response{}, nil
	}

	prefix := "profiles"
	filePath := utils.GenerateFilePath(prefix, userID, string(request.Body.Extension))

	// S3にアップロードするためのURLを取得
	url, err := utils.GetUploadPresignedURL(ctx, filePath)
	if err != nil {
		return gen.CreateProfileImage500Response{}, err
	}

	// 既にプロフィール画像が登録されているか確認
	isExist, err := u.queries.IsProfileImageExistsByUserID(ctx, userID)
	if err != nil {
		return gen.CreateProfileImage500Response{}, err
	}
	if isExist {
		return gen.CreateProfileImage409Response{}, nil
	}

	// プロフィール画像を登録
	arg := db.InsertProfileImageParams{UserID: userID, FilePath: filePath}
	if err = u.queries.InsertProfileImage(ctx, arg); err != nil {
		return gen.CreateProfileImage500Response{}, err
	}

	return gen.CreateProfileImage201JSONResponse{
		UploadUrl: url,
	}, nil
}

func (u *profileUseCase) UpdateProfileImage(ctx context.Context, request gen.UpdateProfileImageRequestObject) (gen.UpdateProfileImageResponseObject, error) {

	// TODO: 本来はここでAuth0の認可が済んだuser_idをcontextから取得
	userID := int64(1)

	// png. jpeg, jpgのみ許可
	switch request.Body.Extension {
	case "png", "jpeg", "jpg":
		break
	default:
		return gen.UpdateProfileImage400Response{}, nil
	}

	// 既にプロフィール画像が登録されているかを確認し、未登録の場合は404エラーを返す
	image, err := u.queries.FindProfileImageByUserID(ctx, userID)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return gen.UpdateProfileImage404Response{}, nil
		}
		return gen.UpdateProfileImage500Response{}, err
	}

	// uploaded_atがNULLの場合はまだ画像のアップロードが完了していないため403エラーを返す
	if !image.UploadedAt.Valid {
		return gen.UpdateProfileImage403Response{}, nil
	}

	// S3上のプロフィール画像を削除
	if !errors.Is(err, utils.DeleteProfileImage(ctx, image.FilePath)) {
		return gen.UpdateProfileImage500Response{}, err
	}

	// DB上のプロフィール画像を削除
	if err = u.queries.DeleteProfileImageByUserID(ctx, userID); err != nil {
		return gen.UpdateProfileImage500Response{}, err
	}

	prefix := "profiles"
	newFilePath := utils.GenerateFilePath(prefix, userID, string(request.Body.Extension))

	// S3にアップロードするためのURLを取得
	url, err := utils.GetUploadPresignedURL(ctx, newFilePath)
	if err != nil {
		return gen.UpdateProfileImage500Response{}, err
	}

	// プロフィール画像を登録
	arg := db.InsertProfileImageParams{UserID: userID, FilePath: newFilePath}
	if err = u.queries.InsertProfileImage(ctx, arg); err != nil {
		return gen.UpdateProfileImage500Response{}, err
	}

	return gen.UpdateProfileImage201JSONResponse{
		UploadUrl: url,
	}, nil
}

func (u *profileUseCase) DeleteProfileImage(ctx context.Context, request gen.DeleteProfileImageRequestObject) (gen.DeleteProfileImageResponseObject, error) {

	// TODO: 本来はここでAuth0の認可が済んだuser_idをcontextから取得
	userID := int64(1)

	image, err := u.queries.FindProfileImageByUserID(ctx, userID)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return gen.DeleteProfileImage404Response{}, nil
		}
		return gen.DeleteProfileImage500Response{}, err
	}

	// uploaded_atがNULLの場合はまだ画像のアップロードが完了していないため403エラーを返す
	if !image.UploadedAt.Valid {
		return gen.DeleteProfileImage403Response{}, nil
	}

	if !errors.Is(err, utils.DeleteProfileImage(ctx, image.FilePath)) {
		return gen.DeleteProfileImage500Response{}, err
	}

	// DB上のプロフィール画像を削除
	if err = u.queries.DeleteProfileImageByUserID(ctx, userID); err != nil {
		return gen.DeleteProfileImage500Response{}, err
	}

	return gen.DeleteProfileImage204Response{}, nil
}
