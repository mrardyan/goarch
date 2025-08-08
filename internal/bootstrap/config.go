package bootstrap

import (
	"fmt"
	"os"

	"golang-arch/internal/shared/config"

	"github.com/spf13/viper"
)

// LoadConfig loads application configuration from environment variables and config files
func LoadConfig() (*config.AppConfig, error) {
	viper.SetConfigName("config")
	viper.SetConfigType("yaml")
	viper.AddConfigPath(".")
	viper.AddConfigPath("./config")
	viper.AddConfigPath("./config")

	// Set default values
	viper.SetDefault("server.port", 8080)
	viper.SetDefault("server.host", "0.0.0.0")
	viper.SetDefault("database.host", "localhost")
	viper.SetDefault("database.port", 5432)
	viper.SetDefault("database.name", "golang_arch")
	viper.SetDefault("database.user", "postgres")
	viper.SetDefault("database.ssl_mode", "disable")
	viper.SetDefault("redis.host", "localhost")
	viper.SetDefault("redis.port", 6379)
	viper.SetDefault("redis.db", 0)
	viper.SetDefault("log.level", "info")
	viper.SetDefault("log.format", "json")

	// Read environment variables
	viper.AutomaticEnv()

	// Read config file if it exists
	if err := viper.ReadInConfig(); err != nil {
		if _, ok := err.(viper.ConfigFileNotFoundError); !ok {
			return nil, fmt.Errorf("failed to read config file: %w", err)
		}
	}

	// Override with environment variables
	overrideFromEnv("DATABASE_HOST", "database.host")
	overrideFromEnv("DATABASE_PORT", "database.port")
	overrideFromEnv("DATABASE_NAME", "database.name")
	overrideFromEnv("DATABASE_USER", "database.user")
	overrideFromEnv("DATABASE_PASSWORD", "database.password")
	overrideFromEnv("DATABASE_SSL_MODE", "database.ssl_mode")
	overrideFromEnv("REDIS_HOST", "redis.host")
	overrideFromEnv("REDIS_PORT", "redis.port")
	overrideFromEnv("REDIS_PASSWORD", "redis.password")
	overrideFromEnv("REDIS_DB", "redis.db")
	overrideFromEnv("SERVER_PORT", "server.port")
	overrideFromEnv("LOG_LEVEL", "log.level")

	var config config.AppConfig
	if err := viper.Unmarshal(&config); err != nil {
		return nil, fmt.Errorf("failed to unmarshal config: %w", err)
	}

	return &config, nil
}

func overrideFromEnv(envKey, configKey string) {
	if value := os.Getenv(envKey); value != "" {
		viper.Set(configKey, value)
	}
}
