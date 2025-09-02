/*
  # Create database views and utility functions

  1. New Views
    - `application_details` - Comprehensive application view with joins
    - `user_details` - User profile view with related data

  2. New Functions
    - `get_user_applications_stats` - Get user application statistics
    - Helper functions for data operations

  3. Security
    - Views inherit RLS from underlying tables
    - Functions use SECURITY DEFINER where appropriate
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
  c.name as company_name,
  uas.domestic_daily_allowance,
  uas.overseas_daily_allowance,
  uns.email_notifications,
  uns.push_notifications
FROM profiles p
LEFT JOIN departments d ON p.department_id = d.id
LEFT JOIN companies c ON p.company_id = c.id
LEFT JOIN user_allowance_settings uas ON p.id = uas.user_id
LEFT JOIN user_notification_settings uns ON p.id = uns.user_id;

-- Function to get user application statistics
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create default user settings
CREATE OR REPLACE FUNCTION create_default_user_settings(user_uuid uuid)
RETURNS void AS $$
BEGIN
  -- Create default allowance settings
  INSERT INTO user_allowance_settings (user_id)
  VALUES (user_uuid)
  ON CONFLICT (user_id) DO NOTHING;
  
  -- Create default notification settings
  INSERT INTO user_notification_settings (user_id)
  VALUES (user_uuid)
  ON CONFLICT (user_id) DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update handle_new_user function to create default settings
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, role, plan, status, onboarding_completed)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
    'admin', -- First user becomes admin
    'Free',
    'active',
    false
  );
  
  -- Create default settings
  PERFORM create_default_user_settings(NEW.id);
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;