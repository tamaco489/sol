package controller

import (
	"context"

	"github.com/takeuchima0/sol/internal/gen"
)

func (c *Controllers) CreateProfile(ctx context.Context, request gen.CreateProfileRequestObject) (response gen.CreateProfileResponseObject, err error) {

	res, err := c.ProfileUseCase.CreateProfile(ctx, request)
	if err != nil {
		return nil, err
	}

	return res, nil
}

func (c *Controllers) GetProfileImage(ctx context.Context, request gen.GetProfileImageRequestObject) (response gen.GetProfileImageResponseObject, err error) {

	res, err := c.ProfileUseCase.GetProfileImage(ctx, request)
	if err != nil {
		return nil, err
	}

	return res, nil
}

func (c *Controllers) CreateProfileImage(ctx context.Context, request gen.CreateProfileImageRequestObject) (response gen.CreateProfileImageResponseObject, err error) {

	res, err := c.ProfileUseCase.CreateProfileImage(ctx, request)
	if err != nil {
		return nil, err
	}

	return res, nil
}

func (c *Controllers) UpdateProfileImage(ctx context.Context, request gen.UpdateProfileImageRequestObject) (response gen.UpdateProfileImageResponseObject, err error) {

	res, err := c.ProfileUseCase.UpdateProfileImage(ctx, request)
	if err != nil {
		return nil, err
	}

	return res, nil
}

func (c *Controllers) DeleteProfileImage(ctx context.Context, request gen.DeleteProfileImageRequestObject) (response gen.DeleteProfileImageResponseObject, err error) {

	res, err := c.ProfileUseCase.DeleteProfileImage(ctx, request)
	if err != nil {
		return nil, err
	}

	return res, nil
}
