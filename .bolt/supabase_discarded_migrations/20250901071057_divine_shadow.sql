/*
  # ビューと最終設定

  1. ビューの作成
    - application_details (申請詳細ビュー)
    - user_details (ユーザー詳細ビュー)

  2. 最終設定
    - 権限の確認
    - 制約の確認
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

-- ユーザー詳細ビュー（JOINを簡素化）
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

-- ビューのRLS設定
ALTER VIEW application_details SET (security_invoker = true);
ALTER VIEW user_details SET (security_invoker = true);

-- 制約の追加
ALTER TABLE applications ADD CONSTRAINT check_start_end_date CHECK (start_date <= end_date OR start_date IS NULL OR end_date IS NULL);
ALTER TABLE applications ADD CONSTRAINT check_amount_positive CHECK (amount >= 0 OR amount IS NULL);
ALTER TABLE expense_items ADD CONSTRAINT check_expense_amount_positive CHECK (amount >= 0);
ALTER TABLE user_allowance_settings ADD CONSTRAINT check_allowances_non_negative CHECK (
  domestic_daily_allowance >= 0 AND
  domestic_accommodation >= 0 AND
  domestic_transportation >= 0 AND
  overseas_daily_allowance >= 0 AND
  overseas_accommodation >= 0 AND
  overseas_transportation >= 0 AND
  overseas_preparation_fee >= 0
);

-- 一意制約の追加
ALTER TABLE departments ADD CONSTRAINT unique_department_name_per_company UNIQUE (company_id, name);
ALTER TABLE regulation_positions ADD CONSTRAINT unique_position_per_regulation UNIQUE (regulation_id, position_name);