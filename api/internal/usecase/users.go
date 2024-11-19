package usecase

import (
	"context"
	"database/sql"

	"github.com/takeuchima0/sol/internal/db"
	"github.com/takeuchima0/sol/internal/gen"
)

type UserUseCase interface {
	CreateUser(ctx context.Context) (gen.CreateUserResponseObject, error)
}

type userUseCase struct {
	queries *db.Queries
}

func NewUserUseCase(queries *db.Queries) UserUseCase {
	return &userUseCase{
		queries: queries,
	}
}

func (u *userUseCase) CreateUser(ctx context.Context) (gen.CreateUserResponseObject, error) {

	// TODO: ここでAuth0の認可が済んだuser_idをcontextから取得(一旦ダミー値を設定)
	auth0UserID := "auth0|fsE94z8fyTh32Mhd0nnA"

	_, err := u.queries.FindUserByAuth0UserID(ctx, auth0UserID)
	if err != nil && err != sql.ErrNoRows {
		return gen.CreateUser500Response{}, err
	}

	result, err := u.queries.InsertUser(ctx, auth0UserID)
	if err != nil {
		return gen.CreateUser500Response{}, err
	}

	newUserID, err := result.LastInsertId()
	if err != nil {
		return gen.CreateUser500Response{}, err
	}

	return gen.CreateUser201JSONResponse{
		UserId: newUserID,
	}, nil
}
