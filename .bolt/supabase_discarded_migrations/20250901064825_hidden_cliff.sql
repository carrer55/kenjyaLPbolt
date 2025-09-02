/*
  # インデックスの作成

  1. Performance Indexes
    - applications テーブルの検索・フィルタリング用インデックス
    - notifications テーブルの検索用インデックス
    - application_timeline テーブルの検索用インデックス

  2. Security
    - No RLS needed for indexes
*/

-- applicationsテーブルのインデックス
CREATE INDEX IF NOT EXISTS idx_applications_applicant_user_id ON public.applications(applicant_user_id);
CREATE INDEX IF NOT EXISTS idx_applications_department_id ON public.applications(department_id);
CREATE INDEX IF NOT EXISTS idx_applications_status ON public.applications(status);
CREATE INDEX IF NOT EXISTS idx_applications_type ON public.applications(type);
CREATE INDEX IF NOT EXISTS idx_applications_submitted_at ON public.applications(submitted_at DESC);
CREATE INDEX IF NOT EXISTS idx_applications_current_approver ON public.applications(current_approver_user_id);

-- expense_itemsテーブルのインデックス
CREATE INDEX IF NOT EXISTS idx_expense_items_application_id ON public.expense_items(application_id);
CREATE INDEX IF NOT EXISTS idx_expense_items_date ON public.expense_items(date DESC);

-- application_timelineテーブルのインデックス
CREATE INDEX IF NOT EXISTS idx_application_timeline_application_id ON public.application_timeline(application_id);
CREATE INDEX IF NOT EXISTS idx_application_timeline_timestamp ON public.application_timeline(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_application_timeline_user_id ON public.application_timeline(user_id);

-- notificationsテーブルのインデックス
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_timestamp ON public.notifications(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON public.notifications(read);

-- profilesテーブルのインデックス
CREATE INDEX IF NOT EXISTS idx_profiles_department_id ON public.profiles(department_id);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_status ON public.profiles(status);

-- travel_regulationsテーブルのインデックス
CREATE INDEX IF NOT EXISTS idx_travel_regulations_created_by ON public.travel_regulations(created_by_user_id);
CREATE INDEX IF NOT EXISTS idx_travel_regulations_status ON public.travel_regulations(status);
CREATE INDEX IF NOT EXISTS idx_travel_regulations_created_at ON public.travel_regulations(created_at DESC);

-- documentsテーブルのインデックス
CREATE INDEX IF NOT EXISTS idx_documents_created_by ON public.documents(created_by_user_id);
CREATE INDEX IF NOT EXISTS idx_documents_application_id ON public.documents(application_id);
CREATE INDEX IF NOT EXISTS idx_documents_type ON public.documents(type);
CREATE INDEX IF NOT EXISTS idx_documents_status ON public.documents(status);