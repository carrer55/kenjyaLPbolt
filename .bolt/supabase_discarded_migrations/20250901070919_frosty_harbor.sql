/*
  # 賢者の精算システム - データベーススキーマ作成

  1. ENUM型の作成
    - user_role (ユーザー役割)
    - user_plan (プラン)
    - user_status (ユーザーステータス)
    - application_type (申請種別)
    - application_status (申請ステータス)
    - regulation_status (規程ステータス)
    - document_type (書類種別)
    - document_status (書類ステータス)
    - notification_type (通知種別)
    - notification_category (通知カテゴリ)
    - legal_category (法令カテゴリ)
    - importance_level (重要度)

  2. テーブルの作成
    - companies (会社)
    - departments (部署)
    - profiles (ユーザープロファイル)
    - applications (申請)
    - expense_items (経費項目)
    - application_timeline (申請履歴)
    - travel_regulations (出張規程)
    - regulation_positions (規程役職別手当)
    - documents (書類)
    - notifications (通知)
    - user_allowance_settings (ユーザー手当設定)
    - user_notification_settings (ユーザー通知設定)
    - faqs (よくある質問)
    - legal_guides (法令ガイド)

  3. セキュリティ
    - 全テーブルでRLS有効化
    - 適切なアクセス制御ポリシー設定

  4. 自動化
    - 新規ユーザー登録時の自動プロファイル作成
    - 申請ステータス変更時の自動ログ記録
    - updated_at自動更新
*/

-- ENUM型の作成
CREATE TYPE user_role AS ENUM ('admin', 'department_admin', 'approver', 'general_user');
CREATE TYPE user_plan AS ENUM ('Free', 'Pro', 'Enterprise');
CREATE TYPE user_status AS ENUM ('active', 'invited', 'inactive');
CREATE TYPE application_type AS ENUM ('business_trip', 'expense');
CREATE TYPE application_status AS ENUM ('draft', 'pending', 'returned', 'approved', 'rejected', 'on_hold', 'submitted');
CREATE TYPE regulation_status AS ENUM ('active', 'draft', 'archived');
CREATE TYPE document_type AS ENUM ('business_report', 'expense_report', 'allowance_detail', 'travel_detail', 'gps_log', 'monthly_report', 'annual_report');
CREATE TYPE document_status AS ENUM ('draft', 'submitted', 'approved', 'rejected');
CREATE TYPE notification_type AS ENUM ('email', 'push');
CREATE TYPE notification_category AS ENUM ('approval', 'reminder', 'system', 'update');
CREATE TYPE legal_category AS ENUM ('law', 'regulation', 'tax', 'guide');
CREATE TYPE importance_level AS ENUM ('high', 'medium', 'low');

-- 1. companies テーブル
CREATE TABLE IF NOT EXISTS companies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  address text,
  representative text,
  phone_number text,
  email text,
  established_date date,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE companies ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Companies can be read by authenticated users"
  ON companies
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Companies can be managed by admins"
  ON companies
  FOR ALL
  TO authenticated
  USING (
    auth.uid() IN (
      SELECT id FROM profiles WHERE role = 'admin'
    )
  );

-- 2. departments テーブル
CREATE TABLE IF NOT EXISTS departments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid REFERENCES companies(id) ON DELETE CASCADE,
  name text NOT NULL,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE departments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Departments can be read by authenticated users"
  ON departments
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Departments can be managed by admins"
  ON departments
  FOR ALL
  TO authenticated
  USING (
    auth.uid() IN (
      SELECT id FROM profiles WHERE role = 'admin'
    )
  );

-- 3. profiles テーブル
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name text,
  company_id uuid REFERENCES companies(id),
  company_name text,
  position text,
  phone_number text,
  role user_role NOT NULL DEFAULT 'general_user',
  plan user_plan NOT NULL DEFAULT 'Free',
  department_id uuid REFERENCES departments(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  invited_by_user_id uuid REFERENCES profiles(id),
  status user_status NOT NULL DEFAULT 'active',
  last_login_at timestamptz,
  onboarding_completed boolean DEFAULT false
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own profile"
  ON profiles
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Admins can read all profiles"
  ON profiles
  FOR SELECT
  TO authenticated
  USING (
    auth.uid() IN (
      SELECT id FROM profiles WHERE role = 'admin'
    )
  );

CREATE POLICY "Department admins can read department profiles"
  ON profiles
  FOR SELECT
  TO authenticated
  USING (
    auth.uid() IN (
      SELECT id FROM profiles 
      WHERE role = 'department_admin' 
      AND department_id = profiles.department_id
    )
  );

CREATE POLICY "Users can update own profile"
  ON profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Admins can update all profiles"
  ON profiles
  FOR UPDATE
  TO authenticated
  USING (
    auth.uid() IN (
      SELECT id FROM profiles WHERE role = 'admin'
    )
  );

CREATE POLICY "Admins can insert profiles"
  ON profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() IN (
      SELECT id FROM profiles WHERE role = 'admin'
    ) OR auth.uid() = id
  );

-- 4. applications テーブル
CREATE TABLE IF NOT EXISTS applications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  type application_type NOT NULL,
  title text NOT NULL,
  applicant_user_id uuid NOT NULL REFERENCES profiles(id),
  department_id uuid NOT NULL REFERENCES departments(id),
  amount numeric(10, 2),
  submitted_at timestamptz DEFAULT now(),
  status application_status NOT NULL DEFAULT 'draft',
  current_approver_user_id uuid REFERENCES profiles(id),
  purpose text,
  start_date date,
  end_date date,
  location text,
  visit_target text,
  companions text,
  approved_at timestamptz,
  approver_comment text,
  estimated_daily_allowance numeric(10, 2),
  estimated_transportation numeric(10, 2),
  estimated_accommodation numeric(10, 2),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE applications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own applications"
  ON applications
  FOR SELECT
  TO authenticated
  USING (applicant_user_id = auth.uid());

CREATE POLICY "Approvers can read assigned applications"
  ON applications
  FOR SELECT
  TO authenticated
  USING (current_approver_user_id = auth.uid());

CREATE POLICY "Department admins can read department applications"
  ON applications
  FOR SELECT
  TO authenticated
  USING (
    auth.uid() IN (
      SELECT id FROM profiles 
      WHERE role = 'department_admin' 
      AND department_id = applications.department_id
    )
  );

CREATE POLICY "Admins can read all applications"
  ON applications
  FOR SELECT
  TO authenticated
  USING (
    auth.uid() IN (
      SELECT id FROM profiles WHERE role = 'admin'
    )
  );

CREATE POLICY "Users can create own applications"
  ON applications
  FOR INSERT
  TO authenticated
  WITH CHECK (applicant_user_id = auth.uid());

CREATE POLICY "Users can update own draft applications"
  ON applications
  FOR UPDATE
  TO authenticated
  USING (
    applicant_user_id = auth.uid() AND status = 'draft'
  );

CREATE POLICY "Approvers can update assigned applications"
  ON applications
  FOR UPDATE
  TO authenticated
  USING (current_approver_user_id = auth.uid());

CREATE POLICY "Admins can update all applications"
  ON applications
  FOR UPDATE
  TO authenticated
  USING (
    auth.uid() IN (
      SELECT id FROM profiles WHERE role = 'admin'
    )
  );

-- 5. expense_items テーブル
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

ALTER TABLE expense_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage expense items for own applications"
  ON expense_items
  FOR ALL
  TO authenticated
  USING (
    application_id IN (
      SELECT id FROM applications WHERE applicant_user_id = auth.uid()
    )
  );

CREATE POLICY "Approvers can read expense items for assigned applications"
  ON expense_items
  FOR SELECT
  TO authenticated
  USING (
    application_id IN (
      SELECT id FROM applications WHERE current_approver_user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can manage all expense items"
  ON expense_items
  FOR ALL
  TO authenticated
  USING (
    auth.uid() IN (
      SELECT id FROM profiles WHERE role = 'admin'
    )
  );

-- 6. application_timeline テーブル
CREATE TABLE IF NOT EXISTS application_timeline (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id uuid NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  timestamp timestamptz DEFAULT now(),
  action text NOT NULL,
  status_change application_status,
  user_id uuid NOT NULL REFERENCES profiles(id),
  comment text,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE application_timeline ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read timeline for accessible applications"
  ON application_timeline
  FOR SELECT
  TO authenticated
  USING (
    application_id IN (
      SELECT id FROM applications 
      WHERE applicant_user_id = auth.uid() 
      OR current_approver_user_id = auth.uid()
      OR auth.uid() IN (SELECT id FROM profiles WHERE role = 'admin')
    )
  );

CREATE POLICY "System can insert timeline entries"
  ON application_timeline
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- 7. travel_regulations テーブル
CREATE TABLE IF NOT EXISTS travel_regulations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid REFERENCES companies(id),
  company_name text NOT NULL,
  company_address text,
  company_representative text,
  established_date date,
  revision integer NOT NULL DEFAULT 1,
  version text NOT NULL,
  created_at timestamptz DEFAULT now(),
  created_by_user_id uuid NOT NULL REFERENCES profiles(id),
  updated_at timestamptz DEFAULT now(),
  status regulation_status NOT NULL DEFAULT 'draft',
  distance_threshold_km integer,
  is_transportation_real_expense boolean DEFAULT false,
  is_accommodation_real_expense boolean DEFAULT false,
  use_preparation_fee boolean DEFAULT true,
  full_text_content text,
  custom_articles jsonb
);

ALTER TABLE travel_regulations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Regulations can be read by authenticated users"
  ON travel_regulations
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can manage regulations"
  ON travel_regulations
  FOR ALL
  TO authenticated
  USING (
    auth.uid() IN (
      SELECT id FROM profiles WHERE role = 'admin'
    )
  );

-- 8. regulation_positions テーブル
CREATE TABLE IF NOT EXISTS regulation_positions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  regulation_id uuid NOT NULL REFERENCES travel_regulations(id) ON DELETE CASCADE,
  position_name text NOT NULL,
  domestic_daily_allowance numeric(10, 2) NOT NULL,
  domestic_accommodation numeric(10, 2) NOT NULL,
  domestic_transportation numeric(10, 2) NOT NULL,
  overseas_daily_allowance numeric(10, 2) NOT NULL,
  overseas_accommodation numeric(10, 2) NOT NULL,
  overseas_transportation numeric(10, 2) NOT NULL,
  overseas_preparation_fee numeric(10, 2) NOT NULL,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE regulation_positions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Regulation positions can be read by authenticated users"
  ON regulation_positions
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can manage regulation positions"
  ON regulation_positions
  FOR ALL
  TO authenticated
  USING (
    auth.uid() IN (
      SELECT id FROM profiles WHERE role = 'admin'
    )
  );

-- 9. documents テーブル
CREATE TABLE IF NOT EXISTS documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id uuid REFERENCES applications(id) ON DELETE SET NULL,
  type document_type NOT NULL,
  title text NOT NULL,
  created_by_user_id uuid NOT NULL REFERENCES profiles(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  status document_status NOT NULL DEFAULT 'draft',
  content_json jsonb,
  attachments_urls text[],
  file_url text
);

ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own documents"
  ON documents
  FOR SELECT
  TO authenticated
  USING (created_by_user_id = auth.uid());

CREATE POLICY "Admins can read all documents"
  ON documents
  FOR SELECT
  TO authenticated
  USING (
    auth.uid() IN (
      SELECT id FROM profiles WHERE role = 'admin'
    )
  );

CREATE POLICY "Users can manage own documents"
  ON documents
  FOR ALL
  TO authenticated
  USING (created_by_user_id = auth.uid());

-- 10. notifications テーブル
CREATE TABLE IF NOT EXISTS notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type notification_type NOT NULL,
  title text NOT NULL,
  message text NOT NULL,
  timestamp timestamptz DEFAULT now(),
  read boolean DEFAULT false,
  category notification_category NOT NULL,
  related_application_id uuid REFERENCES applications(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own notifications"
  ON notifications
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can update own notifications"
  ON notifications
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "System can create notifications"
  ON notifications
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- 11. user_allowance_settings テーブル
CREATE TABLE IF NOT EXISTS user_allowance_settings (
  user_id uuid PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  domestic_daily_allowance numeric(10, 2) NOT NULL DEFAULT 0,
  domestic_accommodation numeric(10, 2) NOT NULL DEFAULT 0,
  domestic_transportation numeric(10, 2) NOT NULL DEFAULT 0,
  domestic_accommodation_disabled boolean DEFAULT false,
  domestic_transportation_disabled boolean DEFAULT false,
  overseas_daily_allowance numeric(10, 2) NOT NULL DEFAULT 0,
  overseas_accommodation numeric(10, 2) NOT NULL DEFAULT 0,
  overseas_transportation numeric(10, 2) NOT NULL DEFAULT 0,
  overseas_preparation_fee numeric(10, 2) NOT NULL DEFAULT 0,
  overseas_accommodation_disabled boolean DEFAULT false,
  overseas_transportation_disabled boolean DEFAULT false,
  overseas_preparation_fee_disabled boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE user_allowance_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own allowance settings"
  ON user_allowance_settings
  FOR ALL
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Admins can read all allowance settings"
  ON user_allowance_settings
  FOR SELECT
  TO authenticated
  USING (
    auth.uid() IN (
      SELECT id FROM profiles WHERE role = 'admin'
    )
  );

-- 12. user_notification_settings テーブル
CREATE TABLE IF NOT EXISTS user_notification_settings (
  user_id uuid PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  email_notifications boolean NOT NULL DEFAULT true,
  push_notifications boolean NOT NULL DEFAULT true,
  reminder_time time NOT NULL DEFAULT '09:00:00',
  approval_only boolean NOT NULL DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE user_notification_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own notification settings"
  ON user_notification_settings
  FOR ALL
  TO authenticated
  USING (user_id = auth.uid());

-- 13. faqs テーブル
CREATE TABLE IF NOT EXISTS faqs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  category text NOT NULL,
  question text NOT NULL,
  answer text NOT NULL,
  display_order integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE faqs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "FAQs can be read by authenticated users"
  ON faqs
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can manage FAQs"
  ON faqs
  FOR ALL
  TO authenticated
  USING (
    auth.uid() IN (
      SELECT id FROM profiles WHERE role = 'admin'
    )
  );

-- 14. legal_guides テーブル
CREATE TABLE IF NOT EXISTS legal_guides (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text NOT NULL,
  url text NOT NULL,
  category legal_category NOT NULL,
  importance importance_level NOT NULL,
  last_updated date NOT NULL,
  display_order integer DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE legal_guides ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Legal guides can be read by authenticated users"
  ON legal_guides
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can manage legal guides"
  ON legal_guides
  FOR ALL
  TO authenticated
  USING (
    auth.uid() IN (
      SELECT id FROM profiles WHERE role = 'admin'
    )
  );

-- インデックスの作成
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_department_id ON profiles(department_id);
CREATE INDEX IF NOT EXISTS idx_profiles_status ON profiles(status);
CREATE INDEX IF NOT EXISTS idx_applications_applicant_user_id ON applications(applicant_user_id);
CREATE INDEX IF NOT EXISTS idx_applications_department_id ON applications(department_id);
CREATE INDEX IF NOT EXISTS idx_applications_status ON applications(status);
CREATE INDEX IF NOT EXISTS idx_applications_submitted_at ON applications(submitted_at);
CREATE INDEX IF NOT EXISTS idx_applications_current_approver_user_id ON applications(current_approver_user_id);
CREATE INDEX IF NOT EXISTS idx_expense_items_application_id ON expense_items(application_id);
CREATE INDEX IF NOT EXISTS idx_application_timeline_application_id ON application_timeline(application_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(read);
CREATE INDEX IF NOT EXISTS idx_travel_regulations_company_id ON travel_regulations(company_id);
CREATE INDEX IF NOT EXISTS idx_regulation_positions_regulation_id ON regulation_positions(regulation_id);
CREATE INDEX IF NOT EXISTS idx_documents_created_by_user_id ON documents(created_by_user_id);

-- updated_at自動更新のためのトリガー関数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- updated_atトリガーの設定
CREATE TRIGGER update_companies_updated_at BEFORE UPDATE ON companies FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_applications_updated_at BEFORE UPDATE ON applications FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_travel_regulations_updated_at BEFORE UPDATE ON travel_regulations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_documents_updated_at BEFORE UPDATE ON documents FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_allowance_settings_updated_at BEFORE UPDATE ON user_allowance_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_notification_settings_updated_at BEFORE UPDATE ON user_notification_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_faqs_updated_at BEFORE UPDATE ON faqs FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 新規ユーザー登録時の自動プロファイル作成
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, role, plan, status, onboarding_completed)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
    'general_user',
    'Free',
    'active',
    false
  );
  
  -- デフォルトの手当設定を作成
  INSERT INTO public.user_allowance_settings (user_id)
  VALUES (NEW.id);
  
  -- デフォルトの通知設定を作成
  INSERT INTO public.user_notification_settings (user_id)
  VALUES (NEW.id);
  
  RETURN NEW;
END;
$$ language 'plpgsql' security definer;

-- 新規ユーザー登録時のトリガー
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- 申請ステータス変更時の自動ログ記録
CREATE OR REPLACE FUNCTION log_application_status_change()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    INSERT INTO public.application_timeline (
      application_id,
      action,
      status_change,
      user_id,
      comment
    ) VALUES (
      NEW.id,
      CASE NEW.status
        WHEN 'pending' THEN '申請提出'
        WHEN 'approved' THEN '承認'
        WHEN 'rejected' THEN '否認'
        WHEN 'returned' THEN '差戻し'
        WHEN 'on_hold' THEN '保留'
        ELSE 'ステータス変更'
      END,
      NEW.status,
      COALESCE(NEW.current_approver_user_id, NEW.applicant_user_id),
      NEW.approver_comment
    );
  END IF;
  RETURN NEW;
END;
$$ language 'plpgsql' security definer;

-- 申請ステータス変更時のトリガー
CREATE TRIGGER on_application_status_change
  AFTER UPDATE ON applications
  FOR EACH ROW EXECUTE FUNCTION log_application_status_change();

-- ユーザー統計取得関数
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
    COALESCE(SUM(amount) FILTER (WHERE DATE_TRUNC('month', submitted_at) = DATE_TRUNC('month', CURRENT_DATE)), 0) as current_month_amount
  FROM applications
  WHERE applicant_user_id = user_uuid;
END;
$$ language 'plpgsql' security definer;