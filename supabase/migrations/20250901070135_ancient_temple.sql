/*
  # Create documents table

  1. New Tables
    - `documents`
      - `id` (uuid, primary key)
      - `application_id` (uuid, foreign key to applications)
      - `type` (document_type enum)
      - `title` (text, not null)
      - `created_by_user_id` (uuid, foreign key to profiles)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)
      - `status` (document_status enum)
      - `content_json` (jsonb)
      - `attachments_urls` (text array)
      - `file_url` (text)

  2. Security
    - Enable RLS on `documents` table
    - Add policies for document access
*/

-- Create documents table
CREATE TABLE IF NOT EXISTS documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id uuid REFERENCES applications(id) ON DELETE SET NULL,
  type document_type NOT NULL,
  title text NOT NULL,
  created_by_user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  status document_status NOT NULL DEFAULT 'draft',
  content_json jsonb,
  attachments_urls text[],
  file_url text
);

-- Add comments
COMMENT ON TABLE documents IS '出張報告書や経費精算書などの生成された書類を格納するテーブル';
COMMENT ON COLUMN documents.application_id IS '関連する申請のID（任意）';
COMMENT ON COLUMN documents.type IS '書類の種別';
COMMENT ON COLUMN documents.content_json IS '書類の内容をJSON形式で格納';
COMMENT ON COLUMN documents.attachments_urls IS '添付ファイルのURL配列';
COMMENT ON COLUMN documents.file_url IS '生成されたファイル（PDF/Word）のURL';

-- Enable RLS
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view own documents"
  ON documents
  FOR SELECT
  TO authenticated
  USING (created_by_user_id = auth.uid());

CREATE POLICY "Users can manage own documents"
  ON documents
  FOR ALL
  TO authenticated
  USING (created_by_user_id = auth.uid());

CREATE POLICY "Admin users can view all documents"
  ON documents
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'admin'
    )
  );

CREATE POLICY "Admin users can manage all documents"
  ON documents
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'admin'
    )
  );

-- Create updated_at trigger
CREATE TRIGGER update_documents_updated_at
  BEFORE UPDATE ON documents
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();