/*
  # データベース関数の作成

  1. Functions
    - handle_new_user() - 新規ユーザー登録時のプロファイル作成
    - update_application_status() - 申請ステータス更新時のタイムライン記録
    - get_user_applications_stats() - ユーザーの申請統計取得

  2. Triggers
    - on_auth_user_created - 新規ユーザー作成時のトリガー
    - on_application_status_change - 申請ステータス変更時のトリガー
*/

-- 新規ユーザー登録時のプロファイル作成関数
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, role, plan, status)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
    'general_user',
    'Free',
    'active'
  );
  
  -- デフォルトの手当設定を作成
  INSERT INTO public.user_allowance_settings (user_id) VALUES (NEW.id);
  
  -- デフォルトの通知設定を作成
  INSERT INTO public.user_notification_settings (user_id) VALUES (NEW.id);
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 申請ステータス更新時のタイムライン記録関数
CREATE OR REPLACE FUNCTION public.update_application_timeline()
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
      COALESCE(NEW.current_approver_user_id, auth.uid()),
      NEW.approver_comment
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ユーザーの申請統計取得関数
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

-- 新規ユーザー作成時のトリガー
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 申請ステータス変更時のトリガー
CREATE OR REPLACE TRIGGER on_application_status_change
  AFTER UPDATE ON public.applications
  FOR EACH ROW EXECUTE FUNCTION public.update_application_timeline();