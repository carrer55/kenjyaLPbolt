/*
  # 部署テーブルの作成

  1. New Tables
    - `departments`
      - `id` (uuid, primary key)
      - `name` (text, unique, not null) - 部署名
      - `created_at` (timestamp) - 作成日時

  2. Security
    - Enable RLS on `departments` table
    - Add policy for authenticated users to read departments
    - Add policy for admin users to manage departments
*/

-- 部署テーブルの作成
CREATE TABLE IF NOT EXISTS public.departments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE public.departments IS '部署情報を格納するテーブル';

-- RLSを有効化
ALTER TABLE public.departments ENABLE ROW LEVEL SECURITY;

-- 認証済みユーザーは全ての部署を参照可能
CREATE POLICY "Authenticated users can read departments"
  ON public.departments
  FOR SELECT
  TO authenticated
  USING (true);

-- 管理者のみが部署を作成・更新・削除可能
CREATE POLICY "Admin users can manage departments"
  ON public.departments
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );