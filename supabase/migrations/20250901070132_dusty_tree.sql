/*
  # Create document-related ENUM types

  1. New Types
    - `document_type` enum with values: business_report, expense_report, allowance_detail, travel_detail, gps_log, monthly_report, annual_report
    - `document_status` enum with values: draft, submitted, approved, rejected

  2. Security
    - No RLS needed for ENUM types
*/

-- Create document type enum
DO $$ BEGIN
  CREATE TYPE document_type AS ENUM ('business_report', 'expense_report', 'allowance_detail', 'travel_detail', 'gps_log', 'monthly_report', 'annual_report');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Create document status enum
DO $$ BEGIN
  CREATE TYPE document_status AS ENUM ('draft', 'submitted', 'approved', 'rejected');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- Add comments
COMMENT ON TYPE document_type IS '書類の種別を定義するENUM型';
COMMENT ON TYPE document_status IS '書類のステータスを定義するENUM型';