package main

import (
	"context"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"

	"github.com/takeuchima0/sol/internal/configuration"
	"github.com/takeuchima0/sol/internal/controller"
)

func main() {
	ctx := context.Background()
	slog.SetDefault(slog.New(slog.NewJSONHandler(os.Stdout, nil)))

	_, err := configuration.Load(ctx)
	if err != nil {
		slog.Error("Failed to read configuration", err)
	}

	srv := controller.NewSOLApiServer()

	go func() {
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			slog.Error("Failed to listen and serve", err)
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	slog.Warn("Shutdown Server ...")

	ctx, cancel := context.WithTimeout(context.Background(), 1)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		slog.Error("Server Shutdown error", err)
	}
	<-ctx.Done()
}
