/*
  # Create regulation-related ENUM types

  1. New Types
    - `regulation_status` enum with values: active, draft, archived

  2. Security
    - No RLS needed for ENUM types
*/

-- Create regulation status enum
DO $$ BEGIN
  CREATE TYPE regulation_status AS ENUM ('active', 'draft', 'archived');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Add comments
COMMENT ON TYPE regulation_status IS '出張規程のステータスを定義するENUM型';