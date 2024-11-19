package controller

import (
	"context"

	"github.com/takeuchima0/sol/internal/gen"
)

func (controller *Controllers) Healthcheck(ctx context.Context, request gen.HealthcheckRequestObject) (gen.HealthcheckResponseObject, error) {
	return gen.Healthcheck200JSONResponse{
		Message: "OK",
	}, nil
}
