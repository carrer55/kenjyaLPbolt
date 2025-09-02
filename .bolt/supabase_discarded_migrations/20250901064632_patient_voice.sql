/*
  # 申請テーブルの作成

  1. New Tables
    - `applications`
      - `id` (uuid, primary key)
      - `type` (application_type) - 申請種別
      - `title` (text) - 申請タイトル
      - `applicant_user_id` (uuid) - 申請者ID
      - `department_id` (uuid) - 部署ID
      - `amount` (numeric) - 予定金額または合計金額
      - `submitted_at` (timestamp) - 提出日時
      - `status` (application_status) - 申請ステータス
      - `current_approver_user_id` (uuid) - 現在の承認者ID
      - `purpose` (text) - 目的
      - `start_date` (date) - 開始日
      - `end_date` (date) - 終了日
      - `location` (text) - 場所
      - `visit_target` (text) - 訪問先
      - `companions` (text) - 同行者
      - `approved_at` (timestamp) - 承認日時
      - `approver_comment` (text) - 承認者コメント

  2. Security
    - Enable RLS on `applications` table
    - Add policy for applicants to read their own applications
    - Add policy for approvers to read applications they need to approve
    - Add policy for department admins to read department applications
    - Add policy for admin users to read all applications
    - Add policy for users to create their own applications
    - Add policy for approvers to update application status
*/

-- 申請テーブルの作成
CREATE TABLE IF NOT EXISTS public.applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type application_type NOT NULL,
  title TEXT NOT NULL,
  applicant_user_id UUID NOT NULL REFERENCES public.profiles(id),
  department_id UUID NOT NULL REFERENCES public.departments(id),
  amount NUMERIC(10, 2),
  submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  status application_status NOT NULL DEFAULT 'draft',
  current_approver_user_id UUID REFERENCES public.profiles(id),
  purpose TEXT,
  start_date DATE,
  end_date DATE,
  location TEXT,
  visit_target TEXT,
  companions TEXT,
  approved_at TIMESTAMP WITH TIME ZONE,
  approver_comment TEXT
);

COMMENT ON TABLE public.applications IS '出張申請および経費申請の基本情報を格納するテーブル';

-- RLSを有効化
ALTER TABLE public.applications ENABLE ROW LEVEL SECURITY;

-- 申請者は自身の申請を参照可能
CREATE POLICY "Applicants can read own applications"
  ON public.applications
  FOR SELECT
  TO authenticated
  USING (applicant_user_id = auth.uid());

-- 承認者は承認が必要な申請を参照可能
CREATE POLICY "Approvers can read applications to approve"
  ON public.applications
  FOR SELECT
  TO authenticated
  USING (
    current_approver_user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role IN ('approver', 'department_admin', 'admin')
    )
  );

-- 部門管理者は自部署の申請を参照可能
CREATE POLICY "Department admin can read department applications"
  ON public.applications
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p1
      WHERE p1.id = auth.uid() 
        AND p1.role = 'department_admin'
        AND p1.department_id = applications.department_id
    )
  );

-- 管理者は全ての申請を参照可能
CREATE POLICY "Admin users can read all applications"
  ON public.applications
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ユーザーは自身の申請を作成可能
CREATE POLICY "Users can create own applications"
  ON public.applications
  FOR INSERT
  TO authenticated
  WITH CHECK (applicant_user_id = auth.uid());

-- 申請者は下書き状態の自身の申請を更新可能
CREATE POLICY "Applicants can update own draft applications"
  ON public.applications
  FOR UPDATE
  TO authenticated
  USING (applicant_user_id = auth.uid() AND status = 'draft');

-- 承認者は承認待ちの申請を更新可能
CREATE POLICY "Approvers can update pending applications"
  ON public.applications
  FOR UPDATE
  TO authenticated
  USING (
    current_approver_user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role IN ('approver', 'department_admin', 'admin')
    )
  );

-- 管理者は全ての申請を管理可能
CREATE POLICY "Admin users can manage all applications"
  ON public.applications
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );