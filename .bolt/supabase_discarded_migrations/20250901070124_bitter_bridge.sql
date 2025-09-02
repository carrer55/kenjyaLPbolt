/*
  # Create regulation_positions table

  1. New Tables
    - `regulation_positions`
      - `id` (uuid, primary key)
      - `regulation_id` (uuid, foreign key to travel_regulations)
      - `position_name` (text, not null)
      - `domestic_daily_allowance` (numeric, not null)
      - `domestic_accommodation` (numeric, not null)
      - `domestic_transportation` (numeric, not null)
      - `overseas_daily_allowance` (numeric, not null)
      - `overseas_accommodation` (numeric, not null)
      - `overseas_transportation` (numeric, not null)
      - `overseas_preparation_fee` (numeric, not null)
      - `created_at` (timestamp)

  2. Security
    - Enable RLS on `regulation_positions` table
    - Add policies for position access
*/

-- Create regulation_positions table
CREATE TABLE IF NOT EXISTS regulation_positions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  regulation_id uuid NOT NULL REFERENCES travel_regulations(id) ON DELETE CASCADE,
  position_name text NOT NULL,
  domestic_daily_allowance numeric(10, 2) NOT NULL DEFAULT 0,
  domestic_accommodation numeric(10, 2) NOT NULL DEFAULT 0,
  domestic_transportation numeric(10, 2) NOT NULL DEFAULT 0,
  overseas_daily_allowance numeric(10, 2) NOT NULL DEFAULT 0,
  overseas_accommodation numeric(10, 2) NOT NULL DEFAULT 0,
  overseas_transportation numeric(10, 2) NOT NULL DEFAULT 0,
  overseas_preparation_fee numeric(10, 2) NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

-- Add comments
COMMENT ON TABLE regulation_positions IS '出張規程内の役職ごとの手当詳細を格納するテーブル';
COMMENT ON COLUMN regulation_positions.regulation_id IS '関連する出張規程のID';
COMMENT ON COLUMN regulation_positions.position_name IS '役職名';
COMMENT ON COLUMN regulation_positions.domestic_daily_allowance IS '国内出張日当';
COMMENT ON COLUMN regulation_positions.domestic_accommodation IS '国内宿泊料';
COMMENT ON COLUMN regulation_positions.domestic_transportation IS '国内交通費';
COMMENT ON COLUMN regulation_positions.overseas_daily_allowance IS '海外出張日当';
COMMENT ON COLUMN regulation_positions.overseas_accommodation IS '海外宿泊料';
COMMENT ON COLUMN regulation_positions.overseas_transportation IS '海外交通費';
COMMENT ON COLUMN regulation_positions.overseas_preparation_fee IS '海外出張支度料';

-- Enable RLS
ALTER TABLE regulation_positions ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Authenticated users can view regulation positions"
  ON regulation_positions
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admin users can manage regulation positions"
  ON regulation_positions
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'admin'
    )
  );