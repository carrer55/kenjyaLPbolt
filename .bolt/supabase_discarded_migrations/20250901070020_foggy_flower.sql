/*
  # Create user-related ENUM types

  1. New Types
    - `user_role` enum with values: admin, department_admin, approver, general_user
    - `user_plan` enum with values: Free, Pro, Enterprise  
    - `user_status` enum with values: active, invited, inactive

  2. Security
    - No RLS needed for ENUM types
*/

-- Create user role enum
DO $$ BEGIN
  CREATE TYPE user_role AS ENUM ('admin', 'department_admin', 'approver', 'general_user');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Create user plan enum  
DO $$ BEGIN
  CREATE TYPE user_plan AS ENUM ('Free', 'Pro', 'Enterprise');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Create user status enum
DO $$ BEGIN
  CREATE TYPE user_status AS ENUM ('active', 'invited', 'inactive');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Add comments
COMMENT ON TYPE user_role IS 'ユーザーの役割を定義するENUM型';
COMMENT ON TYPE user_plan IS 'ユーザーの契約プランを定義するENUM型';
COMMENT ON TYPE user_status IS 'ユーザーのステータスを定義するENUM型';