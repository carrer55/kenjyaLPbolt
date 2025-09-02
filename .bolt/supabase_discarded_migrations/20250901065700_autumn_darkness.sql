/*
  # Core Database Schema Creation

  1. New Tables
    - `companies` - 会社情報
    - `departments` - 部署情報  
    - `profiles` - ユーザープロファイル（auth.usersと連携）
    - `applications` - 申請（出張・経費）
    - `expense_items` - 経費項目詳細
    - `application_timeline` - 申請承認履歴
    - `travel_regulations` - 出張規程
    - `regulation_positions` - 規程内役職別手当
    - `documents` - 生成書類
    - `notifications` - 通知履歴
    - `user_allowance_settings` - ユーザー手当設定
    - `user_notification_settings` - ユーザー通知設定
    - `faqs` - よくある質問
    - `legal_guides` - 法令ガイド

  2. Security
    - Enable RLS on all tables
    - Add comprehensive security policies
    - Role-based access control

  3. Performance
    - Add indexes for efficient queries
    - Create views for complex joins
    - Optimize for application requirements

  4. Automation
    - Auto-create profiles on user registration
    - Auto-log application status changes
    - Auto-update timestamps
*/

-- Create ENUM types first
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

-- Create companies table
CREATE TABLE IF NOT EXISTS companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  address TEXT,
  representative TEXT,
  phone_number TEXT,
  email TEXT,
  established_date DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE companies ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Companies are viewable by authenticated users"
  ON companies
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Companies can be managed by admins"
  ON companies
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Create departments table
CREATE TABLE IF NOT EXISTS departments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE departments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Departments are viewable by authenticated users"
  ON departments
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Departments can be managed by admins"
  ON departments
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Create profiles table
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  company_id UUID REFERENCES companies(id),
  company_name TEXT,
  position TEXT,
  phone_number TEXT,
  role user_role NOT NULL DEFAULT 'general_user',
  plan user_plan NOT NULL DEFAULT 'Free',
  department_id UUID REFERENCES departments(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  invited_by_user_id UUID REFERENCES profiles(id),
  status user_status NOT NULL DEFAULT 'active',
  last_login_at TIMESTAMP WITH TIME ZONE,
  onboarding_completed BOOLEAN DEFAULT FALSE
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
  ON profiles
  FOR SELECT
  TO authenticated
  USING (
    id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role IN ('admin', 'department_admin')
    )
  );

CREATE POLICY "Users can update own profile"
  ON profiles
  FOR UPDATE
  TO authenticated
  USING (
    id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Profiles can be inserted by system"
  ON profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (id = auth.uid());

-- Create applications table
CREATE TABLE IF NOT EXISTS applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type application_type NOT NULL,
  title TEXT NOT NULL,
  applicant_user_id UUID NOT NULL REFERENCES profiles(id),
  department_id UUID NOT NULL REFERENCES departments(id),
  amount NUMERIC(10, 2),
  submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  status application_status NOT NULL DEFAULT 'draft',
  current_approver_user_id UUID REFERENCES profiles(id),
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

ALTER TABLE applications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own applications"
  ON applications
  FOR SELECT
  TO authenticated
  USING (
    applicant_user_id = auth.uid() OR
    current_approver_user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND (
        role = 'admin' OR
        (role = 'department_admin' AND department_id = applications.department_id)
      )
    )
  );

CREATE POLICY "Users can create own applications"
  ON applications
  FOR INSERT
  TO authenticated
  WITH CHECK (applicant_user_id = auth.uid());

CREATE POLICY "Users can update own applications or approvers can update assigned applications"
  ON applications
  FOR UPDATE
  TO authenticated
  USING (
    (applicant_user_id = auth.uid() AND status = 'draft') OR
    (current_approver_user_id = auth.uid() AND status = 'pending') OR
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Create expense_items table
CREATE TABLE IF NOT EXISTS expense_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id UUID NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
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

ALTER TABLE expense_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view expense items for accessible applications"
  ON expense_items
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM applications 
      WHERE id = expense_items.application_id AND (
        applicant_user_id = auth.uid() OR
        current_approver_user_id = auth.uid() OR
        EXISTS (
          SELECT 1 FROM profiles 
          WHERE id = auth.uid() AND (
            role = 'admin' OR
            (role = 'department_admin' AND department_id = applications.department_id)
          )
        )
      )
    )
  );

CREATE POLICY "Users can manage expense items for own applications"
  ON expense_items
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM applications 
      WHERE id = expense_items.application_id AND applicant_user_id = auth.uid()
    )
  );

-- Create application_timeline table
CREATE TABLE IF NOT EXISTS application_timeline (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id UUID NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  action TEXT NOT NULL,
  status_change application_status,
  user_id UUID NOT NULL REFERENCES profiles(id),
  comment TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE application_timeline ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view timeline for accessible applications"
  ON application_timeline
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM applications 
      WHERE id = application_timeline.application_id AND (
        applicant_user_id = auth.uid() OR
        current_approver_user_id = auth.uid() OR
        EXISTS (
          SELECT 1 FROM profiles 
          WHERE id = auth.uid() AND (
            role = 'admin' OR
            (role = 'department_admin' AND department_id = applications.department_id)
          )
        )
      )
    )
  );

CREATE POLICY "System can insert timeline entries"
  ON application_timeline
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Create travel_regulations table
CREATE TABLE IF NOT EXISTS travel_regulations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id),
  company_name TEXT NOT NULL,
  company_address TEXT,
  company_representative TEXT,
  established_date DATE,
  revision INTEGER NOT NULL DEFAULT 1,
  version TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by_user_id UUID NOT NULL REFERENCES profiles(id),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  status regulation_status NOT NULL DEFAULT 'draft',
  distance_threshold_km INTEGER,
  is_transportation_real_expense BOOLEAN DEFAULT FALSE,
  is_accommodation_real_expense BOOLEAN DEFAULT FALSE,
  use_preparation_fee BOOLEAN DEFAULT TRUE,
  full_text_content TEXT,
  custom_articles JSONB
);

ALTER TABLE travel_regulations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Travel regulations are viewable by authenticated users"
  ON travel_regulations
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Travel regulations can be managed by admins"
  ON travel_regulations
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Create regulation_positions table
CREATE TABLE IF NOT EXISTS regulation_positions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  regulation_id UUID NOT NULL REFERENCES travel_regulations(id) ON DELETE CASCADE,
  position_name TEXT NOT NULL,
  domestic_daily_allowance NUMERIC(10, 2) NOT NULL,
  domestic_accommodation NUMERIC(10, 2) NOT NULL,
  domestic_transportation NUMERIC(10, 2) NOT NULL,
  overseas_daily_allowance NUMERIC(10, 2) NOT NULL,
  overseas_accommodation NUMERIC(10, 2) NOT NULL,
  overseas_transportation NUMERIC(10, 2) NOT NULL,
  overseas_preparation_fee NUMERIC(10, 2) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE regulation_positions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Regulation positions are viewable by authenticated users"
  ON regulation_positions
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Regulation positions can be managed by admins"
  ON regulation_positions
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Create documents table
CREATE TABLE IF NOT EXISTS documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id UUID REFERENCES applications(id) ON DELETE SET NULL,
  type document_type NOT NULL,
  title TEXT NOT NULL,
  created_by_user_id UUID NOT NULL REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  status document_status NOT NULL DEFAULT 'draft',
  content_json JSONB,
  attachments_urls TEXT[],
  file_url TEXT
);

ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own documents"
  ON documents
  FOR SELECT
  TO authenticated
  USING (
    created_by_user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Users can manage own documents"
  ON documents
  FOR ALL
  TO authenticated
  USING (created_by_user_id = auth.uid());

-- Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type notification_type NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  read BOOLEAN DEFAULT FALSE,
  category notification_category NOT NULL,
  related_application_id UUID REFERENCES applications(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own notifications"
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

-- Create user_allowance_settings table
CREATE TABLE IF NOT EXISTS user_allowance_settings (
  user_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  domestic_daily_allowance NUMERIC(10, 2) NOT NULL DEFAULT 5000,
  domestic_accommodation NUMERIC(10, 2) NOT NULL DEFAULT 8000,
  domestic_transportation NUMERIC(10, 2) NOT NULL DEFAULT 1500,
  domestic_accommodation_disabled BOOLEAN DEFAULT FALSE,
  domestic_transportation_disabled BOOLEAN DEFAULT FALSE,
  overseas_daily_allowance NUMERIC(10, 2) NOT NULL DEFAULT 8000,
  overseas_accommodation NUMERIC(10, 2) NOT NULL DEFAULT 12000,
  overseas_transportation NUMERIC(10, 2) NOT NULL DEFAULT 2500,
  overseas_preparation_fee NUMERIC(10, 2) NOT NULL DEFAULT 5000,
  overseas_accommodation_disabled BOOLEAN DEFAULT FALSE,
  overseas_transportation_disabled BOOLEAN DEFAULT FALSE,
  overseas_preparation_fee_disabled BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE user_allowance_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own allowance settings"
  ON user_allowance_settings
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can manage own allowance settings"
  ON user_allowance_settings
  FOR ALL
  TO authenticated
  USING (user_id = auth.uid());

-- Create user_notification_settings table
CREATE TABLE IF NOT EXISTS user_notification_settings (
  user_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  email_notifications BOOLEAN NOT NULL DEFAULT TRUE,
  push_notifications BOOLEAN NOT NULL DEFAULT TRUE,
  reminder_time TIME NOT NULL DEFAULT '09:00:00',
  approval_only BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE user_notification_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own notification settings"
  ON user_notification_settings
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can manage own notification settings"
  ON user_notification_settings
  FOR ALL
  TO authenticated
  USING (user_id = auth.uid());

-- Create faqs table
CREATE TABLE IF NOT EXISTS faqs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category TEXT NOT NULL,
  question TEXT NOT NULL,
  answer TEXT NOT NULL,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE faqs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "FAQs are viewable by authenticated users"
  ON faqs
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "FAQs can be managed by admins"
  ON faqs
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Create legal_guides table
CREATE TABLE IF NOT EXISTS legal_guides (
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

ALTER TABLE legal_guides ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Legal guides are viewable by authenticated users"
  ON legal_guides
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Legal guides can be managed by admins"
  ON legal_guides
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_department_id ON profiles(department_id);
CREATE INDEX IF NOT EXISTS idx_profiles_company_id ON profiles(company_id);
CREATE INDEX IF NOT EXISTS idx_applications_applicant_user_id ON applications(applicant_user_id);
CREATE INDEX IF NOT EXISTS idx_applications_department_id ON applications(department_id);
CREATE INDEX IF NOT EXISTS idx_applications_status ON applications(status);
CREATE INDEX IF NOT EXISTS idx_applications_submitted_at ON applications(submitted_at);
CREATE INDEX IF NOT EXISTS idx_applications_current_approver_user_id ON applications(current_approver_user_id);
CREATE INDEX IF NOT EXISTS idx_expense_items_application_id ON expense_items(application_id);
CREATE INDEX IF NOT EXISTS idx_application_timeline_application_id ON application_timeline(application_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(read);
CREATE INDEX IF NOT EXISTS idx_faqs_category ON faqs(category);
CREATE INDEX IF NOT EXISTS idx_legal_guides_category ON legal_guides(category);

-- Create function to handle new user registration
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, role, plan, status, onboarding_completed)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
    'admin'::user_role,
    'Free'::user_plan,
    'active'::user_status,
    FALSE
  );
  
  -- Create default allowance settings
  INSERT INTO public.user_allowance_settings (user_id)
  VALUES (NEW.id);
  
  -- Create default notification settings
  INSERT INTO public.user_notification_settings (user_id)
  VALUES (NEW.id);
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new user registration
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Create function to update updated_at column
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at
CREATE TRIGGER update_companies_updated_at
  BEFORE UPDATE ON companies
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_applications_updated_at
  BEFORE UPDATE ON applications
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_travel_regulations_updated_at
  BEFORE UPDATE ON travel_regulations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_documents_updated_at
  BEFORE UPDATE ON documents
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_allowance_settings_updated_at
  BEFORE UPDATE ON user_allowance_settings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_notification_settings_updated_at
  BEFORE UPDATE ON user_notification_settings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create function to log application status changes
CREATE OR REPLACE FUNCTION log_application_status_change()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    INSERT INTO application_timeline (
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

-- Create trigger for application status changes
CREATE TRIGGER log_application_status_change_trigger
  AFTER UPDATE ON applications
  FOR EACH ROW EXECUTE FUNCTION log_application_status_change();

-- Create function to get user application stats
CREATE OR REPLACE FUNCTION get_user_applications_stats(user_uuid UUID)
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
  FROM applications
  WHERE applicant_user_id = user_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;