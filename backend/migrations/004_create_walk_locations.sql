-- walk_locationsテーブル

CREATE TABLE walk_locations (
  id BIGSERIAL PRIMARY KEY,
  walk_id UUID NOT NULL REFERENCES walks(id) ON DELETE CASCADE,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  altitude DOUBLE PRECISION,
  timestamp TIMESTAMP NOT NULL,
  horizontal_accuracy DOUBLE PRECISION,
  vertical_accuracy DOUBLE PRECISION,
  speed DOUBLE PRECISION,
  course DOUBLE PRECISION,
  sequence_number INTEGER NOT NULL,

  CONSTRAINT chk_latitude CHECK (latitude BETWEEN -90 AND 90),
  CONSTRAINT chk_longitude CHECK (longitude BETWEEN -180 AND 180),
  CONSTRAINT uq_walk_sequence UNIQUE (walk_id, sequence_number)
);

-- インデックス
CREATE INDEX idx_walk_locations_walk_seq ON walk_locations(walk_id, sequence_number);
CREATE INDEX idx_walk_locations_walk_time ON walk_locations(walk_id, timestamp);
