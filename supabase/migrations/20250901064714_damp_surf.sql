/*
  # 規程役職別手当テーブルの作成

  1. New Tables
    - `regulation_positions`
      - `id` (uuid, primary key)
      - `regulation_id` (uuid) - 規程ID
      - `position_name` (text) - 役職名
      - `domestic_daily_allowance` (numeric) - 国内日当
      - `domestic_accommodation` (numeric) - 国内宿泊料
      - `domestic_transportation` (numeric) - 国内交通費
      - `overseas_daily_allowance` (numeric) - 海外日当
      - `overseas_accommodation` (numeric) - 海外宿泊料
      - `overseas_transportation` (numeric) - 海外交通費
      - `overseas_preparation_fee` (numeric) - 海外支度料

  2. Security
    - Enable RLS on `regulation_positions` table
    - Add policy for authenticated users to read positions
    - Add policy for admin users to manage positions
*/

-- 規程役職別手当テーブルの作成
CREATE TABLE IF NOT EXISTS public.regulation_positions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  regulation_id UUID NOT NULL REFERENCES public.travel_regulations(id) ON DELETE CASCADE,
  position_name TEXT NOT NULL,
  domestic_daily_allowance NUMERIC(10, 2) NOT NULL,
  domestic_accommodation NUMERIC(10, 2) NOT NULL,
  domestic_transportation NUMERIC(10, 2) NOT NULL,
  overseas_daily_allowance NUMERIC(10, 2) NOT NULL,
  overseas_accommodation NUMERIC(10, 2) NOT NULL,
  overseas_transportation NUMERIC(10, 2) NOT NULL,
  overseas_preparation_fee NUMERIC(10, 2) NOT NULL
);

COMMENT ON TABLE public.regulation_positions IS '出張規程内の役職ごとの手当詳細を格納するテーブル';

-- RLSを有効化
ALTER TABLE public.regulation_positions ENABLE ROW LEVEL SECURITY;

-- 認証済みユーザーは全ての役職別手当を参照可能
CREATE POLICY "Authenticated users can read regulation positions"
  ON public.regulation_positions
  FOR SELECT
  TO authenticated
  USING (true);

-- 管理者のみが役職別手当を管理可能
CREATE POLICY "Admin users can manage regulation positions"
  ON public.regulation_positions
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );