/*
  # 申請タイムラインテーブルの作成

  1. New Tables
    - `application_timeline`
      - `id` (uuid, primary key)
      - `application_id` (uuid) - 申請ID
      - `timestamp` (timestamp) - タイムスタンプ
      - `action` (text) - アクション内容
      - `status_change` (application_status) - 変更後のステータス
      - `user_id` (uuid) - 実行者ID
      - `comment` (text) - コメント

  2. Security
    - Enable RLS on `application_timeline` table
    - Add policy for users to read timeline of their applications
    - Add policy for approvers to read timeline of applications they can approve
    - Add policy for system to insert timeline entries
*/

-- 申請タイムラインテーブルの作成
CREATE TABLE IF NOT EXISTS public.application_timeline (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id UUID NOT NULL REFERENCES public.applications(id) ON DELETE CASCADE,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  action TEXT NOT NULL,
  status_change application_status,
  user_id UUID NOT NULL REFERENCES public.profiles(id),
  comment TEXT
);

COMMENT ON TABLE public.application_timeline IS '申請の承認履歴やステータス変更を記録するテーブル';

-- RLSを有効化
ALTER TABLE public.application_timeline ENABLE ROW LEVEL SECURITY;

-- 申請に関連するユーザーはタイムラインを参照可能
CREATE POLICY "Related users can read application timeline"
  ON public.application_timeline
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.applications a
      JOIN public.profiles p ON p.id = auth.uid()
      WHERE a.id = application_timeline.application_id
        AND (
          a.applicant_user_id = auth.uid() OR
          a.current_approver_user_id = auth.uid() OR
          p.role IN ('approver', 'department_admin', 'admin') OR
          (p.role = 'department_admin' AND p.department_id = a.department_id)
        )
    )
  );

-- 承認者と管理者はタイムラインエントリを作成可能
CREATE POLICY "Approvers can insert timeline entries"
  ON public.application_timeline
  FOR INSERT
  TO authenticated
  WITH CHECK (
    user_id = auth.uid() AND
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role IN ('approver', 'department_admin', 'admin')
    )
  );

-- 管理者は全てのタイムラインを管理可能
CREATE POLICY "Admin users can manage all timeline entries"
  ON public.application_timeline
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );