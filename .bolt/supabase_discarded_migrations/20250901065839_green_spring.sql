/*
  # Create Remaining Tables

  1. New Tables
    - `travel_regulations` - 出張規程
    - `regulation_positions` - 規程内役職別手当

  2. Security
    - Enable RLS on all new tables
    - Add appropriate security policies

  3. Performance
    - Add necessary indexes
*/

-- Create travel_regulations table
CREATE TABLE IF NOT EXISTS travel_regulations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id),
  company_name TEXT NOT NULL,
  company_address TEXT,
  company_representative TEXT,
  established_date DATE,
  revision INTEGER NOT NULL DEFAULT 1,
  version TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by_user_id UUID NOT NULL REFERENCES profiles(id),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  status regulation_status NOT NULL DEFAULT 'draft',
  distance_threshold_km INTEGER,
  is_transportation_real_expense BOOLEAN DEFAULT FALSE,
  is_accommodation_real_expense BOOLEAN DEFAULT FALSE,
  use_preparation_fee BOOLEAN DEFAULT TRUE,
  full_text_content TEXT,
  custom_articles JSONB
);

ALTER TABLE travel_regulations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Travel regulations are viewable by authenticated users"
  ON travel_regulations
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Travel regulations can be managed by admins"
  ON travel_regulations
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Create regulation_positions table
CREATE TABLE IF NOT EXISTS regulation_positions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  regulation_id UUID NOT NULL REFERENCES travel_regulations(id) ON DELETE CASCADE,
  position_name TEXT NOT NULL,
  domestic_daily_allowance NUMERIC(10, 2) NOT NULL,
  domestic_accommodation NUMERIC(10, 2) NOT NULL,
  domestic_transportation NUMERIC(10, 2) NOT NULL,
  overseas_daily_allowance NUMERIC(10, 2) NOT NULL,
  overseas_accommodation NUMERIC(10, 2) NOT NULL,
  overseas_transportation NUMERIC(10, 2) NOT NULL,
  overseas_preparation_fee NUMERIC(10, 2) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE regulation_positions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Regulation positions are viewable by authenticated users"
  ON regulation_positions
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Regulation positions can be managed by admins"
  ON regulation_positions
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Add indexes for travel regulations
CREATE INDEX IF NOT EXISTS idx_travel_regulations_company_id ON travel_regulations(company_id);
CREATE INDEX IF NOT EXISTS idx_travel_regulations_created_by_user_id ON travel_regulations(created_by_user_id);
CREATE INDEX IF NOT EXISTS idx_travel_regulations_status ON travel_regulations(status);
CREATE INDEX IF NOT EXISTS idx_regulation_positions_regulation_id ON regulation_positions(regulation_id);

-- Add trigger for travel_regulations updated_at
CREATE TRIGGER update_travel_regulations_updated_at
  BEFORE UPDATE ON travel_regulations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();