package controller

import (
	"database/sql"

	"github.com/takeuchima0/sol/internal/db"
	"github.com/takeuchima0/sol/internal/usecase"
)

type Controllers struct {
	env            string
	UserUseCase    usecase.UserUseCase
	ProfileUseCase usecase.ProfileUseCase
}

func NewControllers(env string, queries *db.Queries, db *sql.DB) *Controllers {
	return &Controllers{
		env:            env,
		UserUseCase:    usecase.NewUserUseCase(queries),
		ProfileUseCase: usecase.NewProfileUseCase(queries, db),
	}
}
