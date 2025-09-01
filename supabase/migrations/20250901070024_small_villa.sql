/*
  # Create profiles table

  1. New Tables
    - `profiles`
      - `id` (uuid, primary key, references auth.users)
      - `full_name` (text)
      - `company_id` (uuid, foreign key to companies)
      - `company_name` (text)
      - `position` (text)
      - `phone_number` (text)
      - `role` (user_role enum)
      - `plan` (user_plan enum)
      - `department_id` (uuid, foreign key to departments)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)
      - `invited_by_user_id` (uuid, foreign key to profiles)
      - `status` (user_status enum)
      - `last_login_at` (timestamp)
      - `onboarding_completed` (boolean)

  2. Security
    - Enable RLS on `profiles` table
    - Add policies for user profile access
*/

-- Create profiles table
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name text,
  company_id uuid REFERENCES companies(id) ON DELETE SET NULL,
  company_name text,
  position text,
  phone_number text,
  role user_role NOT NULL DEFAULT 'general_user',
  plan user_plan NOT NULL DEFAULT 'Free',
  department_id uuid REFERENCES departments(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  invited_by_user_id uuid REFERENCES profiles(id) ON DELETE SET NULL,
  status user_status NOT NULL DEFAULT 'active',
  last_login_at timestamptz,
  onboarding_completed boolean DEFAULT false
);

-- Add comments
COMMENT ON TABLE profiles IS 'ユーザーの追加プロファイル情報を格納するテーブル';
COMMENT ON COLUMN profiles.id IS 'auth.usersテーブルのIDへの外部キー';
COMMENT ON COLUMN profiles.role IS 'ユーザーの役割（管理者、部門管理者、承認者、一般ユーザー）';
COMMENT ON COLUMN profiles.plan IS 'ユーザーの契約プラン';
COMMENT ON COLUMN profiles.status IS 'ユーザーのアカウントステータス';
COMMENT ON COLUMN profiles.onboarding_completed IS 'オンボーディング完了フラグ';

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view own profile"
  ON profiles
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Admin users can view all profiles"
  ON profiles
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'admin'
    )
  );

CREATE POLICY "Admin users can manage all profiles"
  ON profiles
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'admin'
    )
  );

CREATE POLICY "Department admins can view department profiles"
  ON profiles
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
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Function to handle new user registration
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, role, plan, status, onboarding_completed)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
    'admin', -- First user becomes admin, others become general_user
    'Free',
    'active',
    false
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new user registration
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();