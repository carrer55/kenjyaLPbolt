/*
  # 経費項目テーブルの作成

  1. New Tables
    - `expense_items`
      - `id` (uuid, primary key)
      - `application_id` (uuid) - 申請ID
      - `category` (text) - 経費カテゴリ
      - `date` (date) - 経費発生日
      - `amount` (numeric) - 金額
      - `description` (text) - 説明
      - `store` (text) - 店舗名
      - `receipt_url` (text) - 領収書URL
      - `ocr_processed` (boolean) - OCR処理済みフラグ
      - `ocr_result_store` (text) - OCR結果：店舗名
      - `ocr_result_date` (date) - OCR結果：日付
      - `ocr_result_amount` (numeric) - OCR結果：金額
      - `ocr_result_confidence` (numeric) - OCR結果：信頼度

  2. Security
    - Enable RLS on `expense_items` table
    - Add policy for applicants to manage their own expense items
    - Add policy for approvers to read expense items
    - Add policy for admin users to manage all expense items
*/

-- 経費項目テーブルの作成
CREATE TABLE IF NOT EXISTS public.expense_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id UUID NOT NULL REFERENCES public.applications(id) ON DELETE CASCADE,
  category TEXT NOT NULL,
  date DATE NOT NULL,
  amount NUMERIC(10, 2) NOT NULL,
  description TEXT,
  store TEXT,
  receipt_url TEXT,
  ocr_processed BOOLEAN DEFAULT FALSE,
  ocr_result_store TEXT,
  ocr_result_date DATE,
  ocr_result_amount NUMERIC(10, 2),
  ocr_result_confidence NUMERIC(5, 2)
);

COMMENT ON TABLE public.expense_items IS '経費申請の詳細項目を格納するテーブル';

-- RLSを有効化
ALTER TABLE public.expense_items ENABLE ROW LEVEL SECURITY;

-- 申請者は自身の申請に関連する経費項目を管理可能
CREATE POLICY "Applicants can manage own expense items"
  ON public.expense_items
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.applications 
      WHERE id = expense_items.application_id 
        AND applicant_user_id = auth.uid()
    )
  );

-- 承認者は承認が必要な申請の経費項目を参照可能
CREATE POLICY "Approvers can read expense items for approval"
  ON public.expense_items
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.applications a
      JOIN public.profiles p ON p.id = auth.uid()
      WHERE a.id = expense_items.application_id
        AND (
          a.current_approver_user_id = auth.uid() OR
          p.role IN ('approver', 'department_admin', 'admin') OR
          (p.role = 'department_admin' AND p.department_id = a.department_id)
        )
    )
  );

-- 管理者は全ての経費項目を管理可能
CREATE POLICY "Admin users can manage all expense items"
  ON public.expense_items
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );