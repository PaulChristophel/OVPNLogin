package main

import (
	"os"
	"testing"
)

func TestLoadConfigFromFile(t *testing.T) {
	// Create a sample TOML configuration file
	configFile := "test_config.toml"
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
	os.WriteFile(configFile, fileContent, 0644)
	defer os.Remove(configFile)

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
	os.Setenv("PGUSER", "env_user")
	os.Setenv("PGPASSWORD", "env_password")
	os.Setenv("PGDATABASE", "env_db")
	os.Setenv("PGHOST", "env_host")
	os.Setenv("PGSSLMODE", "disable")
	os.Setenv("PGPORT", "5432")
	os.Setenv("PGTABLE", "env_table")
	defer os.Clearenv()

	config, err := loadConfig("nonexistent.toml")
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
