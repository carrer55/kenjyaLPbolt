/*
  # ビューと最終関数の作成

  1. ビューの作成
    - application_details (申請詳細ビュー)
    - user_details (ユーザー詳細ビュー)

  2. 統計関数
    - get_user_applications_stats (ユーザー申請統計)

  3. 最終設定
    - Storage設定
    - 追加インデックス
*/

-- 申請詳細ビュー（JOINを簡素化）
CREATE OR REPLACE VIEW application_details AS
SELECT 
  a.*,
  p.full_name as applicant_name,
  d.name as department_name,
  ap.full_name as approver_name,
  c.name as company_name
FROM applications a
LEFT JOIN profiles p ON a.applicant_user_id = p.id
LEFT JOIN departments d ON a.department_id = d.id
LEFT JOIN profiles ap ON a.current_approver_user_id = ap.id
LEFT JOIN companies c ON p.company_id = c.id;

-- ユーザー詳細ビュー
CREATE OR REPLACE VIEW user_details AS
SELECT 
  p.*,
  d.name as department_name,
  uas.domestic_daily_allowance,
  uas.overseas_daily_allowance,
  uns.email_notifications,
  uns.push_notifications
FROM profiles p
LEFT JOIN departments d ON p.department_id = d.id
LEFT JOIN user_allowance_settings uas ON p.id = uas.user_id
LEFT JOIN user_notification_settings uns ON p.id = uns.user_id;

-- 統計データ取得関数の改良版
CREATE OR REPLACE FUNCTION get_user_applications_stats(user_uuid uuid)
RETURNS TABLE(
  total_applications bigint,
  pending_applications bigint,
  approved_applications bigint,
  total_amount numeric,
  current_month_amount numeric
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*) as total_applications,
    COUNT(*) FILTER (WHERE status = 'pending') as pending_applications,
    COUNT(*) FILTER (WHERE status = 'approved') as approved_applications,
    COALESCE(SUM(amount), 0) as total_amount,
    COALESCE(
      SUM(amount) FILTER (
        WHERE DATE_TRUNC('month', submitted_at) = DATE_TRUNC('month', NOW())
      ), 
      0
    ) as current_month_amount
  FROM applications
  WHERE applicant_user_id = user_uuid;
END;
$$ language 'plpgsql' security definer;

-- 部門別統計取得関数
CREATE OR REPLACE FUNCTION get_department_applications_stats(dept_uuid uuid)
RETURNS TABLE(
  total_applications bigint,
  pending_applications bigint,
  approved_applications bigint,
  total_amount numeric,
  current_month_amount numeric
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*) as total_applications,
    COUNT(*) FILTER (WHERE status = 'pending') as pending_applications,
    COUNT(*) FILTER (WHERE status = 'approved') as approved_applications,
    COALESCE(SUM(amount), 0) as total_amount,
    COALESCE(
      SUM(amount) FILTER (
        WHERE DATE_TRUNC('month', submitted_at) = DATE_TRUNC('month', NOW())
      ), 
      0
    ) as current_month_amount
  FROM applications
  WHERE department_id = dept_uuid;
END;
$$ language 'plpgsql' security definer;

-- 承認者用統計取得関数
CREATE OR REPLACE FUNCTION get_approver_applications_stats(approver_uuid uuid)
RETURNS TABLE(
  pending_applications bigint,
  approved_this_month bigint,
  total_approved bigint
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*) FILTER (WHERE status = 'pending' AND current_approver_user_id = approver_uuid) as pending_applications,
    COUNT(*) FILTER (
      WHERE status = 'approved' 
        AND current_approver_user_id = approver_uuid
        AND DATE_TRUNC('month', approved_at) = DATE_TRUNC('month', NOW())
    ) as approved_this_month,
    COUNT(*) FILTER (WHERE status = 'approved' AND current_approver_user_id = approver_uuid) as total_approved
  FROM applications;
END;
$$ language 'plpgsql' security definer;

-- 追加インデックス（パフォーマンス最適化）
CREATE INDEX IF NOT EXISTS idx_applications_status_submitted_at ON applications(status, submitted_at);
CREATE INDEX IF NOT EXISTS idx_applications_type_status ON applications(type, status);
CREATE INDEX IF NOT EXISTS idx_expense_items_date ON expense_items(date);
CREATE INDEX IF NOT EXISTS idx_timeline_timestamp ON application_timeline(timestamp);
CREATE INDEX IF NOT EXISTS idx_notifications_timestamp ON notifications(timestamp);
CREATE INDEX IF NOT EXISTS idx_faqs_category ON faqs(category);