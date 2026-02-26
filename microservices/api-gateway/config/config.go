package config

import (
	"github.com/spf13/viper"
	"log"
)

type Config struct {
	Port              string `mapstructure:"PORT"`
	UserServiceURL    string `mapstructure:"USER_SERVICE_URL"`
	FirebaseCredsFile string `mapstructure:"FIREBASE_CREDS_FILE"`
	InternalSecret    string `mapstructure:"INTERNAL_SECRET"`
}

func LoadConfig() (*Config, error) {
	viper.SetDefault("PORT", "8080")
	viper.SetDefault("USER_SERVICE_URL", "http://localhost:8081")
	viper.SetDefault("FIREBASE_CREDS_FILE", "")
	viper.SetDefault("INTERNAL_SECRET", "default_internal_secret")

	viper.AutomaticEnv()

	var config Config
	if err := viper.Unmarshal(&config); err != nil {
		return nil, err
	}

	log.Printf("Gateway Config loaded: Port=%s, UserSvc=%s", config.Port, config.UserServiceURL)
	return &config, nil
}
