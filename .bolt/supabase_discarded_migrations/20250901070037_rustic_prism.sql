/*
  # Create application-related ENUM types

  1. New Types
    - `application_type` enum with values: business_trip, expense
    - `application_status` enum with values: draft, pending, returned, approved, rejected, on_hold, submitted

  2. Security
    - No RLS needed for ENUM types
*/

-- Create application type enum
DO $$ BEGIN
  CREATE TYPE application_type AS ENUM ('business_trip', 'expense');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Create application status enum
DO $$ BEGIN
  CREATE TYPE application_status AS ENUM ('draft', 'pending', 'returned', 'approved', 'rejected', 'on_hold', 'submitted');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Add comments
COMMENT ON TYPE application_type IS '申請の種別を定義するENUM型（出張申請、経費申請）';
COMMENT ON TYPE application_status IS '申請のステータスを定義するENUM型';