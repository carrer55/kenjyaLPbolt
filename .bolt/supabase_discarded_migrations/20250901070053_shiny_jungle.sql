/*
  # Create expense_items table

  1. New Tables
    - `expense_items`
      - `id` (uuid, primary key)
      - `application_id` (uuid, foreign key to applications)
      - `category` (text, not null)
      - `date` (date, not null)
      - `amount` (numeric, not null)
      - `description` (text)
      - `store` (text)
      - `receipt_url` (text)
      - `ocr_processed` (boolean)
      - `ocr_result_store` (text)
      - `ocr_result_date` (date)
      - `ocr_result_amount` (numeric)
      - `ocr_result_confidence` (numeric)
      - `created_at` (timestamp)

  2. Security
    - Enable RLS on `expense_items` table
    - Add policies for expense item access based on application ownership
*/

-- Create expense_items table
CREATE TABLE IF NOT EXISTS expense_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id uuid NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  category text NOT NULL,
  date date NOT NULL,
  amount numeric(10, 2) NOT NULL,
  description text,
  store text,
  receipt_url text,
  ocr_processed boolean DEFAULT false,
  ocr_result_store text,
  ocr_result_date date,
  ocr_result_amount numeric(10, 2),
  ocr_result_confidence numeric(5, 2),
  created_at timestamptz DEFAULT now()
);

-- Add comments
COMMENT ON TABLE expense_items IS '経費申請の詳細項目を格納するテーブル';
COMMENT ON COLUMN expense_items.application_id IS '関連する申請のID';
COMMENT ON COLUMN expense_items.category IS '経費カテゴリ（例：旅費交通費、接待交際費）';
COMMENT ON COLUMN expense_items.receipt_url IS 'Supabase Storageの領収書画像URL';
COMMENT ON COLUMN expense_items.ocr_processed IS 'OCR処理完了フラグ';
COMMENT ON COLUMN expense_items.ocr_result_confidence IS 'OCR読み取り信頼度（0-100）';

-- Enable RLS
ALTER TABLE expense_items ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view own expense items"
  ON expense_items
  FOR SELECT
  TO authenticated
  USING (
    application_id IN (
      SELECT id FROM applications 
      WHERE applicant_user_id = auth.uid()
    )
  );

CREATE POLICY "Users can manage own expense items"
  ON expense_items
  FOR ALL
  TO authenticated
  USING (
    application_id IN (
      SELECT id FROM applications 
      WHERE applicant_user_id = auth.uid()
    )
  );

CREATE POLICY "Approvers can view assigned expense items"
  ON expense_items
  FOR SELECT
  TO authenticated
  USING (
    application_id IN (
      SELECT id FROM applications 
      WHERE current_approver_user_id = auth.uid()
    )
  );

CREATE POLICY "Admin users can view all expense items"
  ON expense_items
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'admin'
    )
  );

CREATE POLICY "Admin users can manage all expense items"
  ON expense_items
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'admin'
    )
  );