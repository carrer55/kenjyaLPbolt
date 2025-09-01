/*
  # Create companies table

  1. New Tables
    - `companies`
      - `id` (uuid, primary key)
      - `name` (text, unique, not null)
      - `address` (text)
      - `representative` (text)
      - `phone_number` (text)
      - `email` (text)
      - `established_date` (date)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)

  2. Security
    - Enable RLS on `companies` table
    - Add policy for authenticated users to read company data
    - Add policy for admin users to manage company data
*/

-- Create companies table
CREATE TABLE IF NOT EXISTS companies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text UNIQUE NOT NULL,
  address text,
  representative text,
  phone_number text,
  email text,
  established_date date,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Add comments
COMMENT ON TABLE companies IS '会社情報を格納するテーブル';
COMMENT ON COLUMN companies.name IS '会社名';
COMMENT ON COLUMN companies.address IS '会社住所';
COMMENT ON COLUMN companies.representative IS '代表者名';
COMMENT ON COLUMN companies.phone_number IS '電話番号';
COMMENT ON COLUMN companies.email IS 'メールアドレス';
COMMENT ON COLUMN companies.established_date IS '設立日';

-- Enable RLS
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Companies are viewable by authenticated users"
  ON companies
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Companies are manageable by admin users"
  ON companies
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
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_companies_updated_at
  BEFORE UPDATE ON companies
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();