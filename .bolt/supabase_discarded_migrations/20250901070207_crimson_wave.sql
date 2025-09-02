/*
  # Create content tables (FAQs and Legal Guides)

  1. New Tables
    - `faqs`
      - `id` (uuid, primary key)
      - `category` (text, not null)
      - `question` (text, not null)
      - `answer` (text, not null)
      - `display_order` (integer)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)
    - `legal_guides`
      - `id` (uuid, primary key)
      - `title` (text, not null)
      - `description` (text, not null)
      - `url` (text, not null)
      - `category` (legal_category enum)
      - `importance` (importance_level enum)
      - `last_updated` (date)
      - `display_order` (integer)
      - `created_at` (timestamp)

  2. Security
    - Enable RLS on both tables
    - Add policies for content access
*/

-- Create faqs table
CREATE TABLE IF NOT EXISTS faqs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  category text NOT NULL,
  question text NOT NULL,
  answer text NOT NULL,
  display_order integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Add comments for faqs
COMMENT ON TABLE faqs IS 'よくある質問（FAQ）コンテンツを格納するテーブル';
COMMENT ON COLUMN faqs.category IS 'FAQのカテゴリ';
COMMENT ON COLUMN faqs.question IS '質問内容';
COMMENT ON COLUMN faqs.answer IS '回答内容';
COMMENT ON COLUMN faqs.display_order IS '表示順序';

-- Create legal_guides table
CREATE TABLE IF NOT EXISTS legal_guides (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text NOT NULL,
  url text NOT NULL,
  category legal_category NOT NULL,
  importance importance_level NOT NULL,
  last_updated date NOT NULL,
  display_order integer DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

-- Add comments for legal_guides
COMMENT ON TABLE legal_guides IS '法令ガイドコンテンツを格納するテーブル';
COMMENT ON COLUMN legal_guides.title IS 'ガイドのタイトル';
COMMENT ON COLUMN legal_guides.description IS 'ガイドの説明';
COMMENT ON COLUMN legal_guides.url IS '外部リンクURL';
COMMENT ON COLUMN legal_guides.category IS 'ガイドのカテゴリ';
COMMENT ON COLUMN legal_guides.importance IS '重要度レベル';
COMMENT ON COLUMN legal_guides.last_updated IS '最終更新日';

-- Enable RLS
ALTER TABLE faqs ENABLE ROW LEVEL SECURITY;
ALTER TABLE legal_guides ENABLE ROW LEVEL SECURITY;

-- Create policies for faqs
CREATE POLICY "Authenticated users can view FAQs"
  ON faqs
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admin users can manage FAQs"
  ON faqs
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'admin'
    )
  );

-- Create policies for legal_guides
CREATE POLICY "Authenticated users can view legal guides"
  ON legal_guides
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admin users can manage legal guides"
  ON legal_guides
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'admin'
    )
  );

-- Create updated_at trigger for faqs
CREATE TRIGGER update_faqs_updated_at
  BEFORE UPDATE ON faqs
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();