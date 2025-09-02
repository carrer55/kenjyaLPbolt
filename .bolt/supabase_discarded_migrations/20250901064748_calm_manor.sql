/*
  # コンテンツ関連のENUM型の作成

  1. New Types
    - `legal_category` - 法令カテゴリ（law, regulation, tax, guide）
    - `importance_level` - 重要度レベル（high, medium, low）

  2. Security
    - No RLS needed for types
*/

-- 法令カテゴリのENUM型
CREATE TYPE legal_category AS ENUM ('law', 'regulation', 'tax', 'guide');

-- 重要度レベルのENUM型
CREATE TYPE importance_level AS ENUM ('high', 'medium', 'low');