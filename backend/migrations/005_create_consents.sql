-- consentsテーブル

CREATE TABLE consents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id VARCHAR(255) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  policy_version VARCHAR(50) NOT NULL,
  consent_type consent_type NOT NULL,
  consented_at TIMESTAMP NOT NULL DEFAULT NOW(),
  platform VARCHAR(50),
  os_version VARCHAR(100),
  app_version VARCHAR(50)
);

-- インデックス
CREATE INDEX idx_consents_user_consented ON consents(user_id, consented_at DESC);
CREATE INDEX idx_consents_policy_version ON consents(policy_version);
