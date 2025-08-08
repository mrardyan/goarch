package bootstrap

import (
	"database/sql"
	"fmt"
	"log"

	"golang-arch/internal/shared/config"
	"golang-arch/pkg/logger"

	"go.uber.org/zap"
)

// Container holds all application dependencies
type Container struct {
	Config *config.AppConfig
	DB     *sql.DB
	Logger *zap.Logger
	// Add more dependencies as needed
	// Services map[string]interface{}
}

// NewContainer creates and initializes the dependency injection container
func NewContainer(config *config.AppConfig) (*Container, error) {
	// Initialize logger
	logger, err := logger.NewLogger(config.Log.Level, config.Log.Format)
	if err != nil {
		return nil, fmt.Errorf("failed to initialize logger: %w", err)
	}

	// Initialize database connection
	db, err := initDatabase(config.Database)
	if err != nil {
		return nil, fmt.Errorf("failed to initialize database: %w", err)
	}

	container := &Container{
		Config: config,
		DB:     db,
		Logger: logger,
	}

	return container, nil
}

// initDatabase initializes the database connection
func initDatabase(dbConfig config.DatabaseConfig) (*sql.DB, error) {
	dsn := fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=%s",
		dbConfig.Host, dbConfig.Port, dbConfig.User, dbConfig.Password, dbConfig.Name, dbConfig.SSLMode)

	db, err := sql.Open("postgres", dsn)
	if err != nil {
		return nil, fmt.Errorf("failed to open database connection: %w", err)
	}

	// Test the connection
	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	log.Printf("Successfully connected to database: %s:%d/%s", dbConfig.Host, dbConfig.Port, dbConfig.Name)
	return db, nil
}

// Close gracefully closes all container resources
func (c *Container) Close() error {
	if c.DB != nil {
		if err := c.DB.Close(); err != nil {
			return fmt.Errorf("failed to close database connection: %w", err)
		}
	}

	if c.Logger != nil {
		if err := c.Logger.Sync(); err != nil {
			return fmt.Errorf("failed to sync logger: %w", err)
		}
	}

	return nil
}
