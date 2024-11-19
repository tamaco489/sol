package db

import (
	"database/sql"
	"fmt"
	"log/slog"
	"sync"

	mysql_driver "github.com/go-sql-driver/mysql"
	"github.com/takeuchima0/sol/batch/internal/configuration"
)

var (
	instance *sql.DB
	once     sync.Once
)

func InitDB() *sql.DB {
	var err error
	once.Do(func() {
		instance, err = Connect()
		if err != nil {
			panic(err)
		}
	})
	return instance
}

func Connect() (*sql.DB, error) {
	c := mysql_driver.Config{
		User:                 configuration.Get().DB.User,
		Passwd:               configuration.Get().DB.Pass,
		Addr:                 fmt.Sprintf("%s:%s", configuration.Get().DB.Host, configuration.Get().DB.Port),
		DBName:               configuration.Get().DB.Name,
		ParseTime:            true,
		Net:                  "tcp",
		AllowNativePasswords: true,
	}

	slog.Info("[INFO]", " Database Connection | DSN:", c.FormatDSN())

	db, err := sql.Open("mysql", c.FormatDSN())
	if err != nil {
		return nil, err
	}

	if err := db.Ping(); err != nil {
		return nil, err
	}

	return db, err
}
