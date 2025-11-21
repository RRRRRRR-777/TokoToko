-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(128) PRIMARY KEY,           -- Firebase Auth UID
    display_name VARCHAR(255) NOT NULL,
    auth_provider VARCHAR(50) NOT NULL,    -- google, apple...
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create index on auth_provider
CREATE INDEX idx_users_auth_provider ON users(auth_provider);

-- Create index on created_at for sorting
CREATE INDEX idx_users_created_at ON users(created_at DESC);
