-- Create walks table
CREATE TABLE IF NOT EXISTS walks (
    id UUID PRIMARY KEY,
    user_id VARCHAR(128) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    total_distance DOUBLE PRECISION NOT NULL DEFAULT 0,     -- meters
    total_steps INTEGER NOT NULL DEFAULT 0,                 -- step count
    polyline_data TEXT,                                      -- encoded polyline
    thumbnail_image_url TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'not_started',      -- not_started, in_progress, paused, completed
    paused_at TIMESTAMP,
    total_paused_duration DOUBLE PRECISION NOT NULL DEFAULT 0, -- seconds
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create index on user_id for user's walks listing
CREATE INDEX idx_walks_user_id ON walks(user_id);

-- Create index on status for filtering
CREATE INDEX idx_walks_status ON walks(status);

-- Create composite index for user's walks sorted by creation time
CREATE INDEX idx_walks_user_created ON walks(user_id, created_at DESC);

-- Create index on created_at for sorting
CREATE INDEX idx_walks_created_at ON walks(created_at DESC);
