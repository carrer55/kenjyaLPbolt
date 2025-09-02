/*
  # Create indexes and insert sample data

  1. Indexes
    - Performance optimization indexes for common queries
    - Composite indexes for complex filtering

  2. Sample Data
    - Sample departments
    - Sample FAQs
    - Sample legal guides

  3. Security
    - No additional security needed for indexes
    - Sample data follows existing RLS policies
*/

-- Create indexes for performance optimization
CREATE INDEX IF NOT EXISTS idx_applications_applicant_user_id ON applications(applicant_user_id);
CREATE INDEX IF NOT EXISTS idx_applications_department_id ON applications(department_id);
CREATE INDEX IF NOT EXISTS idx_applications_status ON applications(status);
CREATE INDEX IF NOT EXISTS idx_applications_submitted_at ON applications(submitted_at);
CREATE INDEX IF NOT EXISTS idx_applications_type_status ON applications(type, status);

CREATE INDEX IF NOT EXISTS idx_expense_items_application_id ON expense_items(application_id);
CREATE INDEX IF NOT EXISTS idx_expense_items_date ON expense_items(date);
CREATE INDEX IF NOT EXISTS idx_expense_items_category ON expense_items(category);

CREATE INDEX IF NOT EXISTS idx_application_timeline_application_id ON application_timeline(application_id);
CREATE INDEX IF NOT EXISTS idx_application_timeline_timestamp ON application_timeline(timestamp);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(read);
CREATE INDEX IF NOT EXISTS idx_notifications_timestamp ON notifications(timestamp);

CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_department_id ON profiles(department_id);
CREATE INDEX IF NOT EXISTS idx_profiles_company_id ON profiles(company_id);

CREATE INDEX IF NOT EXISTS idx_travel_regulations_company_id ON travel_regulations(company_id);
CREATE INDEX IF NOT EXISTS idx_travel_regulations_status ON travel_regulations(status);

CREATE INDEX IF NOT EXISTS idx_documents_created_by_user_id ON documents(created_by_user_id);
CREATE INDEX IF NOT EXISTS idx_documents_type ON documents(type);
CREATE INDEX IF NOT EXISTS idx_documents_status ON documents(status);

-- Insert sample FAQs
INSERT INTO faqs (category, question, answer, display_order) VALUES
  ('基本操作', '出張申請はどのように行いますか？', '1. ダッシュボードの「出張申請」ボタンをクリック\n2. 出張目的、期間、訪問先を入力\n3. 必要に応じて添付ファイルをアップロード\n4. 「申請を送信」ボタンで提出完了\n\n申請後は承認者に自動で通知が送信されます。', 1),
  ('基本操作', '経費申請の方法を教えてください', '1. ダッシュボードの「経費申請」ボタンをクリック\n2. 経費項目（交通費、宿泊費、日当、雑費）を選択\n3. 日付、金額、説明を入力\n4. 領収書をアップロード（OCR機能で自動読み取り）\n5. 「申請を送信」で提出\n\n複数の経費項目をまとめて申請することも可能です。', 2),
  ('承認・ワークフロー', '承認の流れはどうなっていますか？', '承認フローは以下の順序で進行します：\n\n1. 申請者が提出\n2. 直属の上司が承認\n3. 部長が承認\n4. 経理部が確認\n5. 最終承認者が承認\n\n各段階で承認者に自動通知が送信され、承認・却下の理由もコメントできます。', 3),
  ('出張規程', '出張規程はどのように設定しますか？', '1. サイドバーの「出張規定管理」をクリック\n2. 「新規作成」ボタンで規程作成画面へ\n3. 会社情報、各条文、役職別日当を設定\n4. プレビューで内容を確認\n5. 「規程を保存」で完了\n\nWord/PDF形式での出力も可能です。', 4),
  ('トラブルシューティング', 'ログインできない場合の対処法は？', '以下の手順をお試しください：\n\n1. メールアドレス・パスワードの再確認\n2. ブラウザのキャッシュをクリア\n3. 別のブラウザで試行\n4. パスワードリセット機能を使用\n5. それでも解決しない場合はサポートにお問い合わせください\n\n多要素認証を有効にしている場合は、認証コードも必要です。', 5)
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