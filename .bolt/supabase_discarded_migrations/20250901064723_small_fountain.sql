/*
  # 書類テーブルの作成

  1. New Tables
    - `documents`
      - `id` (uuid, primary key)
      - `application_id` (uuid) - 関連申請ID
      - `type` (document_type) - 書類種別
      - `title` (text) - 書類タイトル
      - `created_by_user_id` (uuid) - 作成者ID
      - `created_at` (timestamp) - 作成日時
      - `updated_at` (timestamp) - 更新日時
      - `status` (document_status) - 書類ステータス
      - `content_json` (jsonb) - 書類内容（JSON形式）
      - `attachments_urls` (text[]) - 添付ファイルURL配列

  2. Security
    - Enable RLS on `documents` table
    - Add policy for creators to manage their own documents
    - Add policy for related users to read documents
    - Add policy for admin users to manage all documents
*/

-- 書類テーブルの作成
CREATE TABLE IF NOT EXISTS public.documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id UUID REFERENCES public.applications(id) ON DELETE SET NULL,
  type document_type NOT NULL,
  title TEXT NOT NULL,
  created_by_user_id UUID NOT NULL REFERENCES public.profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  status document_status NOT NULL DEFAULT 'draft',
  content_json JSONB,
  attachments_urls TEXT[]
);

COMMENT ON TABLE public.documents IS '出張報告書や経費精算書などの生成された書類を格納するテーブル';

-- RLSを有効化
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;

-- 作成者は自身の書類を管理可能
CREATE POLICY "Creators can manage own documents"
  ON public.documents
  FOR ALL
  TO authenticated
  USING (created_by_user_id = auth.uid());

-- 関連する申請の関係者は書類を参照可能
CREATE POLICY "Related users can read documents"
  ON public.documents
  FOR SELECT
  TO authenticated
  USING (
    created_by_user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.applications a
      JOIN public.profiles p ON p.id = auth.uid()
      WHERE a.id = documents.application_id
        AND (
          a.applicant_user_id = auth.uid() OR
          a.current_approver_user_id = auth.uid() OR
          p.role IN ('approver', 'department_admin', 'admin') OR
          (p.role = 'department_admin' AND p.department_id = a.department_id)
        )
    )
  );

-- 管理者は全ての書類を管理可能
CREATE POLICY "Admin users can manage all documents"
  ON public.documents
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );