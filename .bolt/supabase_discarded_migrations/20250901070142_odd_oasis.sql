/*
  # Create notification-related ENUM types

  1. New Types
    - `notification_type` enum with values: email, push
    - `notification_category` enum with values: approval, reminder, system, update

  2. Security
    - No RLS needed for ENUM types
*/

-- Create notification type enum
DO $$ BEGIN
  CREATE TYPE notification_type AS ENUM ('email', 'push');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Create notification category enum
DO $$ BEGIN
  CREATE TYPE notification_category AS ENUM ('approval', 'reminder', 'system', 'update');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Add comments
COMMENT ON TYPE notification_type IS '通知の種別を定義するENUM型';
COMMENT ON TYPE notification_category IS '通知のカテゴリを定義するENUM型';