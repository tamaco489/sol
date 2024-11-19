package controller

import (
	"context"

	"github.com/takeuchima0/sol/internal/gen"
)

func (c *Controllers) CreateUser(ctx context.Context, request gen.CreateUserRequestObject) (response gen.CreateUserResponseObject, err error) {

	res, err := c.UserUseCase.CreateUser(ctx)
	if err != nil {
		return nil, err
	}

	return res, nil
}
