-- ENUM型定義

-- 散歩ステータス
CREATE TYPE walk_status AS ENUM (
  'not_started',
  'in_progress',
  'paused',
  'completed'
);

-- 同意タイプ
CREATE TYPE consent_type AS ENUM (
  'initial',
  'update'
);
