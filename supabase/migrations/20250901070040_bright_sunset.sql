/*
  # Create applications table

  1. New Tables
    - `applications`
      - `id` (uuid, primary key)
      - `type` (application_type enum)
      - `title` (text, not null)
      - `applicant_user_id` (uuid, foreign key to profiles)
      - `department_id` (uuid, foreign key to departments)
      - `amount` (numeric)
      - `submitted_at` (timestamp)
      - `status` (application_status enum)
      - `current_approver_user_id` (uuid, foreign key to profiles)
      - `purpose` (text)
      - `start_date` (date)
      - `end_date` (date)
      - `location` (text)
      - `visit_target` (text)
      - `companions` (text)
      - `approved_at` (timestamp)
      - `approver_comment` (text)
      - `estimated_daily_allowance` (numeric)
      - `estimated_transportation` (numeric)
      - `estimated_accommodation` (numeric)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)

  2. Security
    - Enable RLS on `applications` table
    - Add policies for application access based on user role
*/

-- Create applications table
CREATE TABLE IF NOT EXISTS applications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  type application_type NOT NULL,
  title text NOT NULL,
  applicant_user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  department_id uuid NOT NULL REFERENCES departments(id) ON DELETE RESTRICT,
  amount numeric(12, 2),
  submitted_at timestamptz DEFAULT now(),
  status application_status NOT NULL DEFAULT 'draft',
  current_approver_user_id uuid REFERENCES profiles(id) ON DELETE SET NULL,
  purpose text,
  start_date date,
  end_date date,
  location text,
  visit_target text,
  companions text,
  approved_at timestamptz,
  approver_comment text,
  estimated_daily_allowance numeric(10, 2),
  estimated_transportation numeric(10, 2),
  estimated_accommodation numeric(10, 2),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Add comments
COMMENT ON TABLE applications IS '出張申請および経費申請の基本情報を格納するテーブル';
COMMENT ON COLUMN applications.type IS '申請の種別（出張申請、経費申請）';
COMMENT ON COLUMN applications.applicant_user_id IS '申請者のユーザーID';
COMMENT ON COLUMN applications.department_id IS '申請者の所属部署ID';
COMMENT ON COLUMN applications.amount IS '予定金額または合計金額';
COMMENT ON COLUMN applications.status IS '申請のステータス';
COMMENT ON COLUMN applications.current_approver_user_id IS '現在の承認者のユーザーID';

-- Enable RLS
ALTER TABLE applications ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view own applications"
  ON applications
  FOR SELECT
  TO authenticated
  USING (applicant_user_id = auth.uid());

CREATE POLICY "Users can create own applications"
  ON applications
  FOR INSERT
  TO authenticated
  WITH CHECK (applicant_user_id = auth.uid());

CREATE POLICY "Users can update own draft applications"
  ON applications
  FOR UPDATE
  TO authenticated
  USING (applicant_user_id = auth.uid() AND status = 'draft');

CREATE POLICY "Approvers can view assigned applications"
  ON applications
  FOR SELECT
  TO authenticated
  USING (current_approver_user_id = auth.uid());

CREATE POLICY "Approvers can update assigned applications"
  ON applications
  FOR UPDATE
  TO authenticated
  USING (current_approver_user_id = auth.uid() AND status = 'pending');

CREATE POLICY "Admin users can view all applications"
  ON applications
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'admin'
    )
  );

CREATE POLICY "Admin users can manage all applications"
  ON applications
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'admin'
    )
  );

CREATE POLICY "Department admins can view department applications"
  ON applications
  FOR SELECT
  TO authenticated
  USING (
    department_id IN (
      SELECT department_id FROM profiles 
      WHERE id = auth.uid() 
      AND role = 'department_admin'
    )
  );

-- Create updated_at trigger
CREATE TRIGGER update_applications_updated_at
  BEFORE UPDATE ON applications
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();