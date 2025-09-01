/*
  # 規程関連のENUM型の作成

  1. New Types
    - `regulation_status` - 規程ステータス（active, draft, archived）

  2. Security
    - No RLS needed for types
*/

-- 規程ステータスのENUM型
CREATE TYPE regulation_status AS ENUM ('active', 'draft', 'archived');