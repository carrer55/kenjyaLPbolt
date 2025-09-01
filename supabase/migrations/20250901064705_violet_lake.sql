/*
  # 出張規程テーブルの作成

  1. New Tables
    - `travel_regulations`
      - `id` (uuid, primary key)
      - `company_name` (text) - 会社名
      - `company_address` (text) - 会社住所
      - `company_representative` (text) - 代表者名
      - `established_date` (date) - 制定日
      - `revision` (integer) - 改訂版
      - `version` (text) - バージョン
      - `created_at` (timestamp) - 作成日時
      - `created_by_user_id` (uuid) - 作成者ID
      - `updated_at` (timestamp) - 更新日時
      - `status` (regulation_status) - ステータス
      - `distance_threshold_km` (integer) - 距離基準
      - `is_transportation_real_expense` (boolean) - 交通費実費フラグ
      - `is_accommodation_real_expense` (boolean) - 宿泊費実費フラグ
      - `use_preparation_fee` (boolean) - 支度料使用フラグ
      - `full_text_content` (text) - 規程全文

  2. Security
    - Enable RLS on `travel_regulations` table
    - Add policy for authenticated users to read regulations
    - Add policy for admin users to manage regulations
*/

-- 出張規程テーブルの作成
CREATE TABLE IF NOT EXISTS public.travel_regulations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_name TEXT NOT NULL,
  company_address TEXT,
  company_representative TEXT,
  established_date DATE,
  revision INTEGER NOT NULL DEFAULT 1,
  version TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by_user_id UUID NOT NULL REFERENCES public.profiles(id),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  status regulation_status NOT NULL DEFAULT 'draft',
  distance_threshold_km INTEGER,
  is_transportation_real_expense BOOLEAN DEFAULT FALSE,
  is_accommodation_real_expense BOOLEAN DEFAULT FALSE,
  use_preparation_fee BOOLEAN DEFAULT TRUE,
  full_text_content TEXT
);

COMMENT ON TABLE public.travel_regulations IS '会社ごとの出張規程のバージョンと内容を格納するテーブル';

-- RLSを有効化
ALTER TABLE public.travel_regulations ENABLE ROW LEVEL SECURITY;

-- 認証済みユーザーは全ての規程を参照可能
CREATE POLICY "Authenticated users can read travel regulations"
  ON public.travel_regulations
  FOR SELECT
  TO authenticated
  USING (true);

-- 管理者のみが規程を管理可能
CREATE POLICY "Admin users can manage travel regulations"
  ON public.travel_regulations
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );