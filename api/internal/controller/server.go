package controller

import (
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/takeuchima0/sol/internal/configuration"
	"github.com/takeuchima0/sol/internal/gen"

	rdb "github.com/takeuchima0/sol/internal/db"
)

type customLogFormat struct {
	Level     string        `json:"level"`
	Tag       string        `json:"tag"`
	Status    int           `json:"status"`
	Method    string        `json:"method"`
	Path      string        `json:"path"`
	IP        string        `json:"ip"`
	Latency   time.Duration `json:"latency"`
	UserAgent string        `json:"user_agent"`
	Host      string        `json:"host"`
	Time      string        `json:"time"`
	Message   string        `json:"message"`
}

func NewSOLApiServer() *http.Server {

	r := gin.Default()
	config := cors.DefaultConfig()
	config.AllowOrigins = []string{"*"}
	config.AllowHeaders = append(config.AllowHeaders, "Authorization", "Access-Control-Allow-Origin")
	r.Use(cors.New(config))
	r.Use(gin.LoggerWithFormatter(func(param gin.LogFormatterParams) string {
		f := customLogFormat{
			Level:     "info",
			Tag:       "access",
			Status:    param.StatusCode,
			Method:    param.Method,
			Path:      param.Path,
			IP:        param.ClientIP,
			Latency:   param.Latency,
			UserAgent: param.Request.UserAgent(),
			Host:      param.Request.Host,
			Time:      param.TimeStamp.Format(time.RFC3339),
			Message:   param.ErrorMessage,
		}
		b, _ := json.Marshal(f)
		return string(b)
	}))

	db := rdb.InitDB()
	dbQueries := rdb.New(db)

	// TODO: Auth0の実装を行い次第有効化
	// r.Use(auth.EnsureValidToken(dbQueries))

	solAPI := NewControllers(configuration.Get().API.Env, dbQueries, db)
	strictServer := gen.NewStrictHandler(solAPI, nil)

	gen.RegisterHandlersWithOptions(
		r,
		strictServer,
		gen.GinServerOptions{BaseURL: "/api/"},
	)

	srv := &http.Server{
		Handler: r,
		Addr:    fmt.Sprintf(":%s", configuration.Get().API.Port),
	}

	return srv
}
