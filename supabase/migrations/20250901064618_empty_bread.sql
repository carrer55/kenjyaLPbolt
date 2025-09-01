/*
  # プロファイルテーブルの作成

  1. New Tables
    - `profiles`
      - `id` (uuid, primary key, references auth.users)
      - `full_name` (text) - フルネーム
      - `company_name` (text) - 会社名
      - `position` (text) - 役職
      - `phone_number` (text) - 電話番号
      - `role` (user_role) - ユーザー役割
      - `plan` (user_plan) - 契約プラン
      - `department_id` (uuid) - 部署ID
      - `created_at` (timestamp) - 作成日時
      - `invited_by_user_id` (uuid) - 招待者ID
      - `status` (user_status) - ステータス
      - `last_login_at` (timestamp) - 最終ログイン日時

  2. Security
    - Enable RLS on `profiles` table
    - Add policy for users to read their own profile
    - Add policy for admin users to read all profiles
    - Add policy for users to update their own profile
    - Add policy for admin users to manage all profiles
*/

-- プロファイルテーブルの作成
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  company_name TEXT,
  position TEXT,
  phone_number TEXT,
  role user_role NOT NULL DEFAULT 'general_user',
  plan user_plan NOT NULL DEFAULT 'Free',
  department_id UUID REFERENCES public.departments(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  invited_by_user_id UUID REFERENCES public.profiles(id),
  status user_status NOT NULL DEFAULT 'active',
  last_login_at TIMESTAMP WITH TIME ZONE
);

COMMENT ON TABLE public.profiles IS 'ユーザーの追加プロファイル情報を格納するテーブル';
COMMENT ON COLUMN public.profiles.id IS 'auth.usersテーブルのIDへの外部キー';
COMMENT ON COLUMN public.profiles.role IS 'ユーザーの役割（管理者、部門管理者、承認者、一般ユーザー）';
COMMENT ON COLUMN public.profiles.plan IS 'ユーザーの契約プラン';

-- RLSを有効化
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- ユーザーは自身のプロファイルを参照可能
CREATE POLICY "Users can read own profile"
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- 管理者は全てのプロファイルを参照可能
CREATE POLICY "Admin users can read all profiles"
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- 部門管理者は自部署のプロファイルを参照可能
CREATE POLICY "Department admin can read department profiles"
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p1
      WHERE p1.id = auth.uid() 
        AND p1.role = 'department_admin'
        AND p1.department_id = profiles.department_id
    )
  );

-- ユーザーは自身のプロファイルを更新可能
CREATE POLICY "Users can update own profile"
  ON public.profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id);

-- 管理者は全てのプロファイルを管理可能
CREATE POLICY "Admin users can manage all profiles"
  ON public.profiles
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- 新規ユーザー登録時のプロファイル作成
CREATE POLICY "Users can insert own profile"
  ON public.profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);