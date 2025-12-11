-- walksテーブル

CREATE TABLE walks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id VARCHAR(255) REFERENCES users(id) ON DELETE SET NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT DEFAULT '',
  start_time TIMESTAMP,
  end_time TIMESTAMP,
  total_distance DOUBLE PRECISION DEFAULT 0.0,
  total_steps INTEGER DEFAULT 0,
  polyline_data TEXT,
  thumbnail_image_url VARCHAR(500),
  status walk_status NOT NULL DEFAULT 'not_started',
  paused_at TIMESTAMP,
  total_paused_duration DOUBLE PRECISION DEFAULT 0.0,  -- seconds
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

  CONSTRAINT chk_walk_times CHECK (
    (start_time IS NULL AND end_time IS NULL) OR
    (start_time IS NOT NULL AND (end_time IS NULL OR end_time >= start_time))
  ),
  CONSTRAINT chk_total_distance CHECK (total_distance >= 0),
  CONSTRAINT chk_total_steps CHECK (total_steps >= 0),
  CONSTRAINT chk_total_paused_duration CHECK (total_paused_duration >= 0)
);

-- インデックス
CREATE INDEX idx_walks_user_created_at ON walks(user_id, created_at DESC)
  WHERE user_id IS NOT NULL;
CREATE INDEX idx_walks_status ON walks(status) WHERE status != 'completed';
CREATE INDEX idx_walks_created_at ON walks(created_at DESC);
