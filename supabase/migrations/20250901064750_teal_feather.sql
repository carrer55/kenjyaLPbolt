/*
  # コンテンツテーブルの作成

  1. New Tables
    - `faqs` - よくある質問
    - `legal_guides` - 法令ガイド

  2. Security
    - Enable RLS on both tables
    - Add policies for authenticated users to read content
    - Add policies for admin users to manage content
*/

-- FAQテーブルの作成
CREATE TABLE IF NOT EXISTS public.faqs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category TEXT NOT NULL,
  question TEXT NOT NULL,
  answer TEXT NOT NULL
);

COMMENT ON TABLE public.faqs IS 'よくある質問（FAQ）コンテンツを格納するテーブル';

-- 法令ガイドテーブルの作成
CREATE TABLE IF NOT EXISTS public.legal_guides (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  url TEXT NOT NULL,
  category legal_category NOT NULL,
  importance importance_level NOT NULL,
  last_updated DATE NOT NULL
);

COMMENT ON TABLE public.legal_guides IS '法令ガイドコンテンツを格納するテーブル';

-- FAQsのRLS設定
ALTER TABLE public.faqs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read faqs"
  ON public.faqs
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admin users can manage faqs"
  ON public.faqs
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Legal guidesのRLS設定
ALTER TABLE public.legal_guides ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read legal guides"
  ON public.legal_guides
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admin users can manage legal guides"
  ON public.legal_guides
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );