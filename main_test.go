package main

import (
	"os"
	"path/filepath"
	"testing"
)

func TestLoadConfigFromFile(t *testing.T) {
	// Create a sample TOML configuration file
	configFile := filepath.Join(t.TempDir(), "test_config.toml")
	fileContent := []byte(`
[database]
user = "test_user"
password = "test_password"
dbname = "test_db"
host = "test_host"
sslmode = "disable"
port = "5432"
table = "test_table"
`)
	if err := os.WriteFile(configFile, fileContent, 0644); err != nil {
		t.Fatalf("failed to write config file: %v", err)
	}

	config, err := loadConfig(configFile)
	if err != nil {
		t.Fatalf("loadConfig failed: %v", err)
	}

	if config.Database.User != "test_user" {
		t.Errorf("Expected user 'test_user', got %s", config.Database.User)
	}
}

func TestLoadConfigFromEnvironment(t *testing.T) {
	// Set environment variables
	t.Setenv("PGUSER", "env_user")
	t.Setenv("PGPASSWORD", "env_password")
	t.Setenv("PGDATABASE", "env_db")
	t.Setenv("PGHOST", "env_host")
	t.Setenv("PGSSLMODE", "disable")
	t.Setenv("PGPORT", "5432")
	t.Setenv("PGTABLE", "env_table")

	configFile := filepath.Join(t.TempDir(), "empty_config.toml")
	if err := os.WriteFile(configFile, nil, 0644); err != nil {
		t.Fatalf("failed to write config file: %v", err)
	}

	config, err := loadConfig(configFile)
	if err != nil {
		t.Fatalf("loadConfig failed: %v", err)
	}

	if config.Database.User != "env_user" {
		t.Errorf("Expected user 'env_user', got %s", config.Database.User)
	}
}

// func TestInvalidArguments(t *testing.T) {
// 	tests := []struct {
// 		name        string
// 		args        []string
// 		expectedErr error
// 	}{
// 		{
// 			name:        "No arguments",
// 			args:        []string{"ovpn_login"},
// 			expectedErr: errors.New("usage: ovpn_login <credentials_file>"),
// 		},
// 	}

// 	for _, test := range tests {
// 		t.Run(test.name, func(t *testing.T) {
// 			os.Args = test.args

// 			var buf bytes.Buffer
// 			log.SetOutput(&buf)
// 			defer log.SetOutput(os.Stderr)

// 			err := main()
// 			if err == nil {
// 				t.Fatal("Expected error, got nil")
// 			}

// 			if err.Error() != test.expectedErr.Error() {
// 				t.Errorf("Expected error: %v, got: %v", test.expectedErr, err)
// 			}
// 		})
// 	}
// }
