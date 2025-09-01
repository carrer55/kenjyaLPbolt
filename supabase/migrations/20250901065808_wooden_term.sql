/*
  # Create Views and Sample Data

  1. Views
    - `application_details` - 申請の詳細情報（JOINされたデータ）
    - `user_details` - ユーザーの詳細情報（JOINされたデータ）

  2. Sample Data
    - 基本的な部署データ
    - FAQデータ
    - 法令ガイドデータ

  3. Additional Functions
    - 統計取得関数
    - データ集計関数
*/

-- Create application_details view
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

-- Create user_details view
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

-- Insert sample departments
INSERT INTO departments (id, name) VALUES
  ('dept-001', '総務部'),
  ('dept-002', '営業部'),
  ('dept-003', '開発部'),
  ('dept-004', '企画部'),
  ('dept-005', '経理部')
ON CONFLICT (id) DO NOTHING;

-- Insert sample FAQs
INSERT INTO faqs (category, question, answer, display_order) VALUES
  ('基本操作', '出張申請はどのように行いますか？', '1. ダッシュボードの「出張申請」ボタンをクリック\n2. 出張目的、期間、訪問先を入力\n3. 必要に応じて添付ファイルをアップロード\n4. 「申請を送信」ボタンで提出完了\n\n申請後は承認者に自動で通知が送信されます。', 1),
  ('基本操作', '経費申請の方法を教えてください', '1. ダッシュボードの「経費申請」ボタンをクリック\n2. 経費項目（交通費、宿泊費、日当、雑費）を選択\n3. 日付、金額、説明を入力\n4. 領収書をアップロード（OCR機能で自動読み取り）\n5. 「申請を送信」で提出\n\n複数の経費項目をまとめて申請することも可能です。', 2),
  ('承認・ワークフロー', '承認の流れはどうなっていますか？', '承認フローは以下の順序で進行します：\n\n1. 申請者が提出\n2. 直属の上司が承認\n3. 部長が承認\n4. 経理部が確認\n5. 最終承認者が承認\n\n各段階で承認者に自動通知が送信され、承認・却下の理由もコメントできます。', 3),
  ('出張規程', '出張規程はどのように設定しますか？', '1. サイドバーの「出張規定管理」をクリック\n2. 「新規作成」ボタンで規程作成画面へ\n3. 会社情報、各条文、役職別日当を設定\n4. プレビューで内容を確認\n5. 「規程を保存」で完了\n\nWord/PDF形式での出力も可能です。', 4),
  ('出張規程', '日当の計算方法を教えてください', '日当は以下のルールで計算されます：\n\n• 日帰り出張：1日分の日当\n• 1泊2日：2日分の日当 + 1泊分の宿泊日当\n• 2泊3日：3日分の日当 + 2泊分の宿泊日当\n\n役職別に異なる日当額が設定でき、海外出張は国内の1.5倍で自動計算されます。', 5)
ON CONFLICT DO NOTHING;

-- Insert sample legal guides
INSERT INTO legal_guides (title, description, url, category, importance, last_updated, display_order) VALUES
  ('所得税法（出張旅費関連）', '出張旅費の非課税限度額や適正な支給基準について定めた法令', 'https://elaws.e-gov.go.jp/document?lawid=340AC0000000033', 'law', 'high', '2024-04-01', 1),
  ('法人税法基本通達（旅費交通費）', '法人の旅費交通費の損金算入要件と適正な支給基準', 'https://www.nta.go.jp/law/tsutatsu/kihon/hojin/09/09_02_01.htm', 'tax', 'high', '2024-04-01', 2),
  ('出張旅費規程作成ガイドライン', '適正な出張旅費規程の作成方法と注意点', 'https://www.nta.go.jp/taxes/shiraberu/taxanswer/gensen/2508.htm', 'guide', 'high', '2024-03-15', 3),
  ('労働基準法（出張時の労働時間）', '出張時の労働時間の取り扱いと休憩時間の規定', 'https://elaws.e-gov.go.jp/document?lawid=322AC0000000049', 'law', 'medium', '2024-04-01', 4),
  ('消費税法（仕入税額控除）', '出張費用の消費税仕入税額控除の適用要件', 'https://www.nta.go.jp/taxes/shiraberu/taxanswer/shohi/6451.htm', 'tax', 'medium', '2024-04-01', 5),
  ('電子帳簿保存法', '出張費用の領収書等の電子保存要件', 'https://www.nta.go.jp/law/joho-zeikaishaku/sonota/jirei/0021006-031.htm', 'regulation', 'high', '2024-01-01', 6)
ON CONFLICT DO NOTHING;

-- Create additional helper functions
CREATE OR REPLACE FUNCTION get_department_applications_stats(dept_id UUID)
RETURNS TABLE (
  total_applications BIGINT,
  pending_applications BIGINT,
  approved_applications BIGINT,
  total_amount NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*) as total_applications,
    COUNT(*) FILTER (WHERE status = 'pending') as pending_applications,
    COUNT(*) FILTER (WHERE status = 'approved') as approved_applications,
    COALESCE(SUM(amount), 0) as total_amount
  FROM applications
  WHERE department_id = dept_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to get monthly application stats
CREATE OR REPLACE FUNCTION get_monthly_application_stats(user_uuid UUID, target_month DATE)
RETURNS TABLE (
  application_count BIGINT,
  total_amount NUMERIC,
  business_trip_count BIGINT,
  expense_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*) as application_count,
    COALESCE(SUM(amount), 0) as total_amount,
    COUNT(*) FILTER (WHERE type = 'business_trip') as business_trip_count,
    COUNT(*) FILTER (WHERE type = 'expense') as expense_count
  FROM applications
  WHERE applicant_user_id = user_uuid
    AND DATE_TRUNC('month', submitted_at) = DATE_TRUNC('month', target_month);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;