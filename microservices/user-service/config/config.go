package config

import (
	"github.com/spf13/viper"
	"log"
)

type Config struct {
	Port           string `mapstructure:"PORT"`
	DBHost         string `mapstructure:"DB_HOST"`
	DBPort         string `mapstructure:"DB_PORT"`
	DBUser         string `mapstructure:"DB_USER"`
	DBPass         string `mapstructure:"DB_PASS"`
	DBName         string `mapstructure:"DB_NAME"`
	InternalSecret string `mapstructure:"INTERNAL_SECRET"`
}

func LoadConfig() (*Config, error) {
	viper.SetDefault("PORT", "8081")
	viper.SetDefault("DB_HOST", "localhost")
	viper.SetDefault("DB_PORT", "5432")
	viper.SetDefault("DB_USER", "postgres")
	viper.SetDefault("DB_PASS", "postgres")
	viper.SetDefault("DB_NAME", "riyo_users")
	viper.SetDefault("INTERNAL_SECRET", "default_internal_secret")

	viper.AutomaticEnv()

	var config Config
	if err := viper.Unmarshal(&config); err != nil {
		return nil, err
	}

	log.Printf("Config loaded: Port=%s, DBHost=%s", config.Port, config.DBHost)
	return &config, nil
}
