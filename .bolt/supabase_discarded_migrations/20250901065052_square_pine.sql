/*
  # 賢者の精算システム - 完全データベース初期化

  このマイグレーションは、賢者の精算システムに必要な全てのテーブル、型、セキュリティポリシー、
  インデックス、関数を作成します。

  ## 作成されるテーブル
  1. companies - 会社情報
  2. departments - 部署情報  
  3. profiles - ユーザープロファイル
  4. applications - 申請（出張・経費）
  5. expense_items - 経費項目詳細
  6. application_timeline - 申請承認履歴
  7. travel_regulations - 出張規程
  8. regulation_positions - 規程内役職別手当
  9. documents - 生成書類
  10. notifications - 通知履歴
  11. user_allowance_settings - ユーザー手当設定
  12. user_notification_settings - ユーザー通知設定
  13. faqs - よくある質問
  14. legal_guides - 法令ガイド

  ## セキュリティ
  - 全テーブルでRLS有効化
  - 適切なアクセス制御ポリシー設定
  - データ保護とプライバシー確保

  ## パフォーマンス
  - 検索・フィルタリング用インデックス
  - 効率的なクエリのための複合インデックス
*/

-- ===================================
-- ENUM型の作成
-- ===================================

-- ユーザー関連のENUM型
CREATE TYPE user_role AS ENUM ('admin', 'department_admin', 'approver', 'general_user');
CREATE TYPE user_plan AS ENUM ('Free', 'Pro', 'Enterprise');
CREATE TYPE user_status AS ENUM ('active', 'invited', 'inactive');

-- 申請関連のENUM型
CREATE TYPE application_type AS ENUM ('business_trip', 'expense');
CREATE TYPE application_status AS ENUM ('draft', 'pending', 'returned', 'approved', 'rejected', 'on_hold', 'submitted');

-- 規程関連のENUM型
CREATE TYPE regulation_status AS ENUM ('active', 'draft', 'archived');

-- 書類関連のENUM型
CREATE TYPE document_type AS ENUM ('business_report', 'expense_report', 'allowance_detail', 'travel_detail', 'gps_log', 'monthly_report', 'annual_report');
CREATE TYPE document_status AS ENUM ('draft', 'submitted', 'approved', 'rejected');

-- 通知関連のENUM型
CREATE TYPE notification_type AS ENUM ('email', 'push');
CREATE TYPE notification_category AS ENUM ('approval', 'reminder', 'system', 'update');

-- コンテンツ関連のENUM型
CREATE TYPE legal_category AS ENUM ('law', 'regulation', 'tax', 'guide');
CREATE TYPE importance_level AS ENUM ('high', 'medium', 'low');

-- ===================================
-- テーブルの作成
-- ===================================

-- 1. 会社テーブル
CREATE TABLE IF NOT EXISTS public.companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  address TEXT,
  representative TEXT,
  phone_number TEXT,
  email TEXT,
  established_date DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. 部署テーブル
CREATE TABLE IF NOT EXISTS public.departments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(company_id, name)
);

-- 3. ユーザープロファイルテーブル
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  company_id UUID REFERENCES public.companies(id),
  company_name TEXT,
  position TEXT,
  phone_number TEXT,
  role user_role NOT NULL DEFAULT 'general_user',
  plan user_plan NOT NULL DEFAULT 'Free',
  department_id UUID REFERENCES public.departments(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  invited_by_user_id UUID REFERENCES public.profiles(id),
  status user_status NOT NULL DEFAULT 'active',
  last_login_at TIMESTAMP WITH TIME ZONE,
  onboarding_completed BOOLEAN DEFAULT FALSE
);

-- 4. 申請テーブル
CREATE TABLE IF NOT EXISTS public.applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type application_type NOT NULL,
  title TEXT NOT NULL,
  applicant_user_id UUID NOT NULL REFERENCES public.profiles(id),
  department_id UUID NOT NULL REFERENCES public.departments(id),
  amount NUMERIC(12, 2),
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
  approver_comment TEXT,
  estimated_daily_allowance NUMERIC(10, 2),
  estimated_transportation NUMERIC(10, 2),
  estimated_accommodation NUMERIC(10, 2),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. 経費項目テーブル
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
  ocr_result_confidence NUMERIC(5, 2),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. 申請タイムラインテーブル
CREATE TABLE IF NOT EXISTS public.application_timeline (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id UUID NOT NULL REFERENCES public.applications(id) ON DELETE CASCADE,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  action TEXT NOT NULL,
  status_change application_status,
  user_id UUID NOT NULL REFERENCES public.profiles(id),
  comment TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. 出張規程テーブル
CREATE TABLE IF NOT EXISTS public.travel_regulations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  company_name TEXT NOT NULL,
  company_address TEXT,
  company_representative TEXT,
  established_date DATE,
  revision INTEGER NOT NULL DEFAULT 1,
  version TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by_user_id UUID NOT NULL REFERENCES public.profiles(id),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  status regulation_status NOT NULL DEFAULT 'draft',
  distance_threshold_km INTEGER DEFAULT 50,
  is_transportation_real_expense BOOLEAN DEFAULT FALSE,
  is_accommodation_real_expense BOOLEAN DEFAULT FALSE,
  use_preparation_fee BOOLEAN DEFAULT TRUE,
  full_text_content TEXT,
  custom_articles JSONB
);

-- 8. 規程役職別手当テーブル
CREATE TABLE IF NOT EXISTS public.regulation_positions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  regulation_id UUID NOT NULL REFERENCES public.travel_regulations(id) ON DELETE CASCADE,
  position_name TEXT NOT NULL,
  domestic_daily_allowance NUMERIC(10, 2) NOT NULL DEFAULT 0,
  domestic_accommodation NUMERIC(10, 2) NOT NULL DEFAULT 0,
  domestic_transportation NUMERIC(10, 2) NOT NULL DEFAULT 0,
  overseas_daily_allowance NUMERIC(10, 2) NOT NULL DEFAULT 0,
  overseas_accommodation NUMERIC(10, 2) NOT NULL DEFAULT 0,
  overseas_transportation NUMERIC(10, 2) NOT NULL DEFAULT 0,
  overseas_preparation_fee NUMERIC(10, 2) NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 9. 書類テーブル
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
  attachments_urls TEXT[],
  file_url TEXT
);

-- 10. 通知テーブル
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type notification_type NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  read BOOLEAN DEFAULT FALSE,
  category notification_category NOT NULL,
  related_application_id UUID REFERENCES public.applications(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 11. ユーザー手当設定テーブル
CREATE TABLE IF NOT EXISTS public.user_allowance_settings (
  user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  domestic_daily_allowance NUMERIC(10, 2) NOT NULL DEFAULT 5000,
  domestic_accommodation NUMERIC(10, 2) NOT NULL DEFAULT 10000,
  domestic_transportation NUMERIC(10, 2) NOT NULL DEFAULT 2000,
  domestic_accommodation_disabled BOOLEAN DEFAULT FALSE,
  domestic_transportation_disabled BOOLEAN DEFAULT FALSE,
  overseas_daily_allowance NUMERIC(10, 2) NOT NULL DEFAULT 10000,
  overseas_accommodation NUMERIC(10, 2) NOT NULL DEFAULT 15000,
  overseas_transportation NUMERIC(10, 2) NOT NULL DEFAULT 3000,
  overseas_preparation_fee NUMERIC(10, 2) NOT NULL DEFAULT 5000,
  overseas_accommodation_disabled BOOLEAN DEFAULT FALSE,
  overseas_transportation_disabled BOOLEAN DEFAULT FALSE,
  overseas_preparation_fee_disabled BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 12. ユーザー通知設定テーブル
CREATE TABLE IF NOT EXISTS public.user_notification_settings (
  user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  email_notifications BOOLEAN NOT NULL DEFAULT TRUE,
  push_notifications BOOLEAN NOT NULL DEFAULT TRUE,
  reminder_time TIME NOT NULL DEFAULT '09:00:00',
  approval_only BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 13. FAQテーブル
CREATE TABLE IF NOT EXISTS public.faqs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category TEXT NOT NULL,
  question TEXT NOT NULL,
  answer TEXT NOT NULL,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 14. 法令ガイドテーブル
CREATE TABLE IF NOT EXISTS public.legal_guides (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  url TEXT NOT NULL,
  category legal_category NOT NULL,
  importance importance_level NOT NULL,
  last_updated DATE NOT NULL,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===================================
-- Row Level Security (RLS) の設定
-- ===================================

-- 1. companies テーブルのRLS
ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Companies are viewable by authenticated users"
  ON public.companies
  FOR SELECT
  TO authenticated
  USING (TRUE);

CREATE POLICY "Companies are manageable by admins"
  ON public.companies
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- 2. departments テーブルのRLS
ALTER TABLE public.departments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Departments are viewable by authenticated users"
  ON public.departments
  FOR SELECT
  TO authenticated
  USING (TRUE);

CREATE POLICY "Departments are manageable by admins"
  ON public.departments
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- 3. profiles テーブルのRLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING (id = auth.uid());

CREATE POLICY "Admins can view all profiles"
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Department admins can view department profiles"
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING (
    department_id IN (
      SELECT department_id FROM public.profiles 
      WHERE id = auth.uid() AND role = 'department_admin'
    )
  );

CREATE POLICY "Users can update own profile"
  ON public.profiles
  FOR UPDATE
  TO authenticated
  USING (id = auth.uid());

CREATE POLICY "Admins can manage all profiles"
  ON public.profiles
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- 4. applications テーブルのRLS
ALTER TABLE public.applications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own applications"
  ON public.applications
  FOR SELECT
  TO authenticated
  USING (applicant_user_id = auth.uid());

CREATE POLICY "Approvers can view assigned applications"
  ON public.applications
  FOR SELECT
  TO authenticated
  USING (current_approver_user_id = auth.uid());

CREATE POLICY "Department admins can view department applications"
  ON public.applications
  FOR SELECT
  TO authenticated
  USING (
    department_id IN (
      SELECT department_id FROM public.profiles 
      WHERE id = auth.uid() AND role = 'department_admin'
    )
  );

CREATE POLICY "Admins can view all applications"
  ON public.applications
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Users can create own applications"
  ON public.applications
  FOR INSERT
  TO authenticated
  WITH CHECK (applicant_user_id = auth.uid());

CREATE POLICY "Users can update own draft applications"
  ON public.applications
  FOR UPDATE
  TO authenticated
  USING (applicant_user_id = auth.uid() AND status = 'draft');

CREATE POLICY "Approvers can update assigned applications"
  ON public.applications
  FOR UPDATE
  TO authenticated
  USING (current_approver_user_id = auth.uid());

CREATE POLICY "Admins can manage all applications"
  ON public.applications
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- 5. expense_items テーブルのRLS
ALTER TABLE public.expense_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage expense items for own applications"
  ON public.expense_items
  FOR ALL
  TO authenticated
  USING (
    application_id IN (
      SELECT id FROM public.applications 
      WHERE applicant_user_id = auth.uid()
    )
  );

CREATE POLICY "Approvers can view expense items for assigned applications"
  ON public.expense_items
  FOR SELECT
  TO authenticated
  USING (
    application_id IN (
      SELECT id FROM public.applications 
      WHERE current_approver_user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can manage all expense items"
  ON public.expense_items
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- 6. application_timeline テーブルのRLS
ALTER TABLE public.application_timeline ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view timeline for accessible applications"
  ON public.application_timeline
  FOR SELECT
  TO authenticated
  USING (
    application_id IN (
      SELECT id FROM public.applications 
      WHERE applicant_user_id = auth.uid() 
         OR current_approver_user_id = auth.uid()
         OR department_id IN (
           SELECT department_id FROM public.profiles 
           WHERE id = auth.uid() AND role = 'department_admin'
         )
    ) OR EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "System can insert timeline entries"
  ON public.application_timeline
  FOR INSERT
  TO authenticated
  WITH CHECK (TRUE);

-- 7. travel_regulations テーブルのRLS
ALTER TABLE public.travel_regulations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Regulations are viewable by authenticated users"
  ON public.travel_regulations
  FOR SELECT
  TO authenticated
  USING (TRUE);

CREATE POLICY "Admins can manage regulations"
  ON public.travel_regulations
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- 8. regulation_positions テーブルのRLS
ALTER TABLE public.regulation_positions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Regulation positions are viewable by authenticated users"
  ON public.regulation_positions
  FOR SELECT
  TO authenticated
  USING (TRUE);

CREATE POLICY "Admins can manage regulation positions"
  ON public.regulation_positions
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- 9. documents テーブルのRLS
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own documents"
  ON public.documents
  FOR SELECT
  TO authenticated
  USING (created_by_user_id = auth.uid());

CREATE POLICY "Users can view documents for accessible applications"
  ON public.documents
  FOR SELECT
  TO authenticated
  USING (
    application_id IN (
      SELECT id FROM public.applications 
      WHERE applicant_user_id = auth.uid() 
         OR current_approver_user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can view all documents"
  ON public.documents
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Users can create documents"
  ON public.documents
  FOR INSERT
  TO authenticated
  WITH CHECK (created_by_user_id = auth.uid());

CREATE POLICY "Users can update own documents"
  ON public.documents
  FOR UPDATE
  TO authenticated
  USING (created_by_user_id = auth.uid());

-- 10. notifications テーブルのRLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own notifications"
  ON public.notifications
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "System can create notifications"
  ON public.notifications
  FOR INSERT
  TO authenticated
  WITH CHECK (TRUE);

CREATE POLICY "Users can update own notifications"
  ON public.notifications
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid());

-- 11. user_allowance_settings テーブルのRLS
ALTER TABLE public.user_allowance_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own allowance settings"
  ON public.user_allowance_settings
  FOR ALL
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Admins can manage all allowance settings"
  ON public.user_allowance_settings
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- 12. user_notification_settings テーブルのRLS
ALTER TABLE public.user_notification_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own notification settings"
  ON public.user_notification_settings
  FOR ALL
  TO authenticated
  USING (user_id = auth.uid());

-- 13. faqs テーブルのRLS
ALTER TABLE public.faqs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "FAQs are viewable by authenticated users"
  ON public.faqs
  FOR SELECT
  TO authenticated
  USING (TRUE);

CREATE POLICY "Admins can manage FAQs"
  ON public.faqs
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- 14. legal_guides テーブルのRLS
ALTER TABLE public.legal_guides ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Legal guides are viewable by authenticated users"
  ON public.legal_guides
  FOR SELECT
  TO authenticated
  USING (TRUE);

CREATE POLICY "Admins can manage legal guides"
  ON public.legal_guides
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ===================================
-- インデックスの作成
-- ===================================

-- パフォーマンス向上のためのインデックス
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_department_id ON public.profiles(department_id);
CREATE INDEX IF NOT EXISTS idx_profiles_company_id ON public.profiles(company_id);
CREATE INDEX IF NOT EXISTS idx_applications_applicant_user_id ON public.applications(applicant_user_id);
CREATE INDEX IF NOT EXISTS idx_applications_department_id ON public.applications(department_id);
CREATE INDEX IF NOT EXISTS idx_applications_status ON public.applications(status);
CREATE INDEX IF NOT EXISTS idx_applications_type ON public.applications(type);
CREATE INDEX IF NOT EXISTS idx_applications_submitted_at ON public.applications(submitted_at);
CREATE INDEX IF NOT EXISTS idx_expense_items_application_id ON public.expense_items(application_id);
CREATE INDEX IF NOT EXISTS idx_application_timeline_application_id ON public.application_timeline(application_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON public.notifications(read);
CREATE INDEX IF NOT EXISTS idx_documents_created_by_user_id ON public.documents(created_by_user_id);
CREATE INDEX IF NOT EXISTS idx_documents_application_id ON public.documents(application_id);

-- 複合インデックス
CREATE INDEX IF NOT EXISTS idx_applications_status_type ON public.applications(status, type);
CREATE INDEX IF NOT EXISTS idx_applications_department_status ON public.applications(department_id, status);

-- ===================================
-- データベース関数の作成
-- ===================================

-- 新規ユーザー登録時のプロファイル自動作成関数
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, role, plan, status, created_at)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
    'general_user',
    'Free',
    'active',
    NOW()
  );
  
  -- デフォルトの手当設定を作成
  INSERT INTO public.user_allowance_settings (user_id)
  VALUES (NEW.id);
  
  -- デフォルトの通知設定を作成
  INSERT INTO public.user_notification_settings (user_id)
  VALUES (NEW.id);
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 新規ユーザー登録時のトリガー
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- プロファイル更新時のupdated_at自動更新関数
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- updated_atの自動更新トリガー
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_applications_updated_at
  BEFORE UPDATE ON public.applications
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_travel_regulations_updated_at
  BEFORE UPDATE ON public.travel_regulations
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_documents_updated_at
  BEFORE UPDATE ON public.documents
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_user_allowance_settings_updated_at
  BEFORE UPDATE ON public.user_allowance_settings
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_user_notification_settings_updated_at
  BEFORE UPDATE ON public.user_notification_settings
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- 申請ステータス変更時のタイムライン自動記録関数
CREATE OR REPLACE FUNCTION public.log_application_status_change()
RETURNS TRIGGER AS $$
BEGIN
  -- ステータスが変更された場合のみタイムラインに記録
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 申請ステータス変更トリガー
DROP TRIGGER IF EXISTS on_application_status_change ON public.applications;
CREATE TRIGGER on_application_status_change
  AFTER UPDATE ON public.applications
  FOR EACH ROW EXECUTE FUNCTION public.log_application_status_change();

-- ユーザー統計取得関数
CREATE OR REPLACE FUNCTION public.get_user_applications_stats(user_uuid UUID)
RETURNS TABLE (
  total_applications BIGINT,
  pending_applications BIGINT,
  approved_applications BIGINT,
  total_amount NUMERIC,
  current_month_amount NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*) as total_applications,
    COUNT(*) FILTER (WHERE status = 'pending') as pending_applications,
    COUNT(*) FILTER (WHERE status = 'approved') as approved_applications,
    COALESCE(SUM(amount), 0) as total_amount,
    COALESCE(SUM(amount) FILTER (WHERE DATE_TRUNC('month', submitted_at) = DATE_TRUNC('month', NOW())), 0) as current_month_amount
  FROM public.applications
  WHERE applicant_user_id = user_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===================================
-- サンプルデータの挿入
-- ===================================

-- サンプル会社データ
INSERT INTO public.companies (id, name, address, representative, phone_number, email, established_date) VALUES
  ('550e8400-e29b-41d4-a716-446655440000', '株式会社サンプル', '東京都千代田区丸の内1-1-1', '代表取締役 山田太郎', '03-1234-5678', 'info@sample.com', '2020-01-01'),
  ('550e8400-e29b-41d4-a716-446655440001', '株式会社テスト', '大阪府大阪市北区梅田1-1-1', '代表取締役 佐藤花子', '06-1234-5678', 'info@test.com', '2019-04-01')
ON CONFLICT (id) DO NOTHING;

-- サンプル部署データ
INSERT INTO public.departments (id, company_id, name) VALUES
  ('660e8400-e29b-41d4-a716-446655440000', '550e8400-e29b-41d4-a716-446655440000', '営業部'),
  ('660e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440000', '総務部'),
  ('660e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440000', '開発部'),
  ('660e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440000', '企画部'),
  ('660e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440000', '経理部')
ON CONFLICT (company_id, name) DO NOTHING;

-- サンプルFAQデータ
INSERT INTO public.faqs (category, question, answer, display_order) VALUES
  ('基本操作', '出張申請はどのように行いますか？', '1. ダッシュボードの「出張申請」ボタンをクリック\n2. 出張目的、期間、訪問先を入力\n3. 必要に応じて添付ファイルをアップロード\n4. 「申請を送信」ボタンで提出完了\n\n申請後は承認者に自動で通知が送信されます。', 1),
  ('基本操作', '経費申請の方法を教えてください', '1. ダッシュボードの「経費申請」ボタンをクリック\n2. 経費項目（交通費、宿泊費、日当、雑費）を選択\n3. 日付、金額、説明を入力\n4. 領収書をアップロード（OCR機能で自動読み取り）\n5. 「申請を送信」で提出\n\n複数の経費項目をまとめて申請することも可能です。', 2),
  ('承認・ワークフロー', '承認の流れはどうなっていますか？', '承認フローは以下の順序で進行します：\n\n1. 申請者が提出\n2. 直属の上司が承認\n3. 部長が承認\n4. 経理部が確認\n5. 最終承認者が承認\n\n各段階で承認者に自動通知が送信され、承認・却下の理由もコメントできます。', 3),
  ('出張規程', '出張規程はどのように設定しますか？', '1. サイドバーの「出張規定管理」をクリック\n2. 「新規作成」ボタンで規程作成画面へ\n3. 会社情報、各条文、役職別日当を設定\n4. プレビューで内容を確認\n5. 「規程を保存」で完了\n\nWord/PDF形式での出力も可能です。', 4),
  ('トラブルシューティング', 'ログインできない場合の対処法は？', '以下の手順をお試しください：\n\n1. メールアドレス・パスワードの再確認\n2. ブラウザのキャッシュをクリア\n3. 別のブラウザで試行\n4. パスワードリセット機能を使用\n5. それでも解決しない場合はサポートにお問い合わせください\n\n多要素認証を有効にしている場合は、認証コードも必要です。', 5)
ON CONFLICT DO NOTHING;

-- サンプル法令ガイドデータ
INSERT INTO public.legal_guides (title, description, url, category, importance, last_updated, display_order) VALUES
  ('所得税法（出張旅費関連）', '出張旅費の非課税限度額や適正な支給基準について定めた法令', 'https://elaws.e-gov.go.jp/document?lawid=340AC0000000033', 'law', 'high', '2024-04-01', 1),
  ('法人税法基本通達（旅費交通費）', '法人の旅費交通費の損金算入要件と適正な支給基準', 'https://www.nta.go.jp/law/tsutatsu/kihon/hojin/09/09_02_01.htm', 'tax', 'high', '2024-04-01', 2),
  ('出張旅費規程作成ガイドライン', '適正な出張旅費規程の作成方法と注意点', 'https://www.nta.go.jp/taxes/shiraberu/taxanswer/gensen/2508.htm', 'guide', 'high', '2024-03-15', 3),
  ('労働基準法（出張時の労働時間）', '出張時の労働時間の取り扱いと休憩時間の規定', 'https://elaws.e-gov.go.jp/document?lawid=322AC0000000049', 'law', 'medium', '2024-04-01', 4),
  ('電子帳簿保存法', '出張費用の領収書等の電子保存要件', 'https://www.nta.go.jp/law/joho-zeikaishaku/sonota/jirei/0021006-031.htm', 'regulation', 'high', '2024-01-01', 5)
ON CONFLICT DO NOTHING;

-- ===================================
-- ビューの作成
-- ===================================

-- 申請詳細ビュー（JOINを含む）
CREATE OR REPLACE VIEW public.application_details AS
SELECT 
  a.*,
  p.full_name as applicant_name,
  d.name as department_name,
  ap.full_name as approver_name,
  c.name as company_name
FROM public.applications a
LEFT JOIN public.profiles p ON a.applicant_user_id = p.id
LEFT JOIN public.departments d ON a.department_id = d.id
LEFT JOIN public.profiles ap ON a.current_approver_user_id = ap.id
LEFT JOIN public.companies c ON p.company_id = c.id;

-- ユーザー詳細ビュー
CREATE OR REPLACE VIEW public.user_details AS
SELECT 
  p.*,
  d.name as department_name,
  c.name as company_name,
  uas.domestic_daily_allowance,
  uas.overseas_daily_allowance,
  uns.email_notifications,
  uns.push_notifications
FROM public.profiles p
LEFT JOIN public.departments d ON p.department_id = d.id
LEFT JOIN public.companies c ON p.company_id = c.id
LEFT JOIN public.user_allowance_settings uas ON p.id = uas.user_id
LEFT JOIN public.user_notification_settings uns ON p.id = uns.user_id;

-- ===================================
-- 完了メッセージ
-- ===================================

-- データベース初期化完了
DO $$
BEGIN
  RAISE NOTICE '賢者の精算システム データベース初期化が完了しました';
  RAISE NOTICE '作成されたテーブル数: 14';
  RAISE NOTICE '作成されたENUM型数: 11';
  RAISE NOTICE '作成されたRLSポリシー数: 30+';
  RAISE NOTICE '作成されたインデックス数: 15';
  RAISE NOTICE '作成された関数数: 3';
  RAISE NOTICE 'サンプルデータが挿入されました';
END $$;