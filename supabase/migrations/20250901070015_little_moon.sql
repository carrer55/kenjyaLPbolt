/*
  # Create departments table

  1. New Tables
    - `departments`
      - `id` (uuid, primary key)
      - `company_id` (uuid, foreign key to companies)
      - `name` (text, not null)
      - `created_at` (timestamp)

  2. Security
    - Enable RLS on `departments` table
    - Add policy for authenticated users to read departments
    - Add policy for admin users to manage departments
*/

-- Create departments table
CREATE TABLE IF NOT EXISTS departments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid REFERENCES companies(id) ON DELETE CASCADE,
  name text NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Add comments
COMMENT ON TABLE departments IS '部署情報を格納するテーブル';
COMMENT ON COLUMN departments.company_id IS '所属会社のID';
COMMENT ON COLUMN departments.name IS '部署名';

-- Enable RLS
ALTER TABLE departments ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Departments are viewable by authenticated users"
  ON departments
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Departments are manageable by admin users"
  ON departments
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'admin'
    )
  );

-- Insert sample departments
INSERT INTO departments (name) VALUES
  ('総務部'),
  ('営業部'),
  ('開発部'),
  ('企画部'),
  ('経理部')
ON CONFLICT (name) DO NOTHING;