/*
  # Create content-related ENUM types

  1. New Types
    - `legal_category` enum with values: law, regulation, tax, guide
    - `importance_level` enum with values: high, medium, low

  2. Security
    - No RLS needed for ENUM types
*/

-- Create legal category enum
DO $$ BEGIN
  CREATE TYPE legal_category AS ENUM ('law', 'regulation', 'tax', 'guide');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Create importance level enum
DO $$ BEGIN
  CREATE TYPE importance_level AS ENUM ('high', 'medium', 'low');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Add comments
COMMENT ON TYPE legal_category IS '法令ガイドのカテゴリを定義するENUM型';
COMMENT ON TYPE importance_level IS '重要度レベルを定義するENUM型';