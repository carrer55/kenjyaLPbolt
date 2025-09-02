/*
  # Create travel_regulations table

  1. New Tables
    - `travel_regulations`
      - `id` (uuid, primary key)
      - `company_id` (uuid, foreign key to companies)
      - `company_name` (text, not null)
      - `company_address` (text)
      - `company_representative` (text)
      - `established_date` (date)
      - `revision` (integer)
      - `version` (text, not null)
      - `created_at` (timestamp)
      - `created_by_user_id` (uuid, foreign key to profiles)
      - `updated_at` (timestamp)
      - `status` (regulation_status enum)
      - `distance_threshold_km` (integer)
      - `is_transportation_real_expense` (boolean)
      - `is_accommodation_real_expense` (boolean)
      - `use_preparation_fee` (boolean)
      - `full_text_content` (text)
      - `custom_articles` (jsonb)

  2. Security
    - Enable RLS on `travel_regulations` table
    - Add policies for regulation access
*/

-- Create travel_regulations table
CREATE TABLE IF NOT EXISTS travel_regulations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid REFERENCES companies(id) ON DELETE CASCADE,
  company_name text NOT NULL,
  company_address text,
  company_representative text,
  established_date date,
  revision integer NOT NULL DEFAULT 1,
  version text NOT NULL,
  created_at timestamptz DEFAULT now(),
  created_by_user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  updated_at timestamptz DEFAULT now(),
  status regulation_status NOT NULL DEFAULT 'draft',
  distance_threshold_km integer,
  is_transportation_real_expense boolean DEFAULT false,
  is_accommodation_real_expense boolean DEFAULT false,
  use_preparation_fee boolean DEFAULT true,
  full_text_content text,
  custom_articles jsonb
);

-- Add comments
COMMENT ON TABLE travel_regulations IS '会社ごとの出張規程のバージョンと内容を格納するテーブル';
COMMENT ON COLUMN travel_regulations.company_id IS '関連する会社のID';
COMMENT ON COLUMN travel_regulations.version IS '規程のバージョン（例：v1.0）';
COMMENT ON COLUMN travel_regulations.distance_threshold_km IS '出張と認定する距離の閾値（km）';
COMMENT ON COLUMN travel_regulations.custom_articles IS '規程の条文をJSON形式で格納';

-- Enable RLS
ALTER TABLE travel_regulations ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Authenticated users can view travel regulations"
  ON travel_regulations
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admin users can manage travel regulations"
  ON travel_regulations
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'admin'
    )
  );

-- Create updated_at trigger
CREATE TRIGGER update_travel_regulations_updated_at
  BEFORE UPDATE ON travel_regulations
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();