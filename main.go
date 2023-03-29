package main

import (
	"database/sql"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"strings"

	"github.com/pelletier/go-toml"

	_ "github.com/lib/pq"
)

type Config struct {
	Database struct {
		User     string
		Password string
		DBName   string
		Host     string
		SSLMode  string `toml:",omitempty"`
		Port     string `toml:",omitempty"`
		Table    string `toml:",omitempty"`
	}
}

func main() {
	if len(os.Args) != 2 {
		log.Fatalf("usage: ovpn_login <credentials_file>")
	}

	credentialsBytes, err := ioutil.ReadFile(os.Args[1])
	if err != nil {
		log.Fatalf("failed to read credentials file: %v", err)
	}
	lines := strings.Split(string(credentialsBytes), "\n")
	if len(lines) < 2 {
		log.Fatalf("credentials file must have at least two lines (username and password)")
	}

	username := lines[0]
	providedPassword := lines[1]

	err = Validate(username, providedPassword)
	if err != nil {
		log.Println(err)
		os.Exit(1)
	}
}

func Validate(username string, providedPassword string) error {
	config, err := loadConfig("/etc/openvpn/ovpn_login.toml")
	if err != nil {
		return err
	}

	connStr := fmt.Sprintf("user=%s password=%s dbname=%s host=%s sslmode=%s port=%s",
		config.Database.User, config.Database.Password, config.Database.DBName, config.Database.Host, config.Database.SSLMode, config.Database.Port)

	db, err := sql.Open("postgres", connStr)
	if err != nil {
		return err
	}
	defer db.Close()

	var passwordMatch bool
	query := fmt.Sprintf("SELECT (password = crypt($2, password)) as password_match FROM %s WHERE username = $1", config.Database.Table)
	err = db.QueryRow(query, username, providedPassword).Scan(&passwordMatch)
	if err != nil {
		return err
	}
	if !passwordMatch {
		return fmt.Errorf("Username or password mismatch")
	}
	return nil
}

func loadConfig(file string) (*Config, error) {
	config := &Config{}
	content, err := toml.LoadFile(file)
	if err == nil {
		err = content.Unmarshal(config)
		if err != nil {
			return nil, err
		}
	}

	// Load environment variables if fields are empty
	if config.Database.User == "" {
		config.Database.User = os.Getenv("PGUSER")
	}
	if config.Database.Password == "" {
		config.Database.Password = os.Getenv("PGPASSWORD")
	}
	if config.Database.DBName == "" {
		config.Database.DBName = os.Getenv("PGDATABASE")
	}
	if config.Database.Host == "" {
		config.Database.Host = os.Getenv("PGHOST")
	}
	if config.Database.SSLMode == "" {
		config.Database.SSLMode = os.Getenv("PGSSLMODE")
		if config.Database.SSLMode == "" {
			config.Database.SSLMode = "prefer" // Default PostgreSQL SSLMode
		}
	}
	if config.Database.Port == "" {
		config.Database.Port = os.Getenv("PGPORT")
		if config.Database.Port == "" {
			config.Database.Port = "5432" // Default PostgreSQL port
		}
	}
	if config.Database.Table == "" {
		config.Database.Table = os.Getenv("PGTABLE")
		if config.Database.Table == "" {
			config.Database.Table = "ovpn_login" // Default table
		}
	}

	return config, nil
}
