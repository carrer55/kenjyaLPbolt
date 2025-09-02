/*
  # ユーザー設定テーブルの作成

  1. New Tables
    - `user_allowance_settings` - ユーザー手当設定
    - `user_notification_settings` - ユーザー通知設定

  2. Security
    - Enable RLS on both tables
    - Add policies for users to manage their own settings
    - Add policies for admin users to manage all settings
*/

-- ユーザー手当設定テーブルの作成
CREATE TABLE IF NOT EXISTS public.user_allowance_settings (
  user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  domestic_daily_allowance NUMERIC(10, 2) NOT NULL DEFAULT 0,
  domestic_accommodation NUMERIC(10, 2) NOT NULL DEFAULT 0,
  domestic_transportation NUMERIC(10, 2) NOT NULL DEFAULT 0,
  domestic_accommodation_disabled BOOLEAN DEFAULT FALSE,
  domestic_transportation_disabled BOOLEAN DEFAULT FALSE,
  overseas_daily_allowance NUMERIC(10, 2) NOT NULL DEFAULT 0,
  overseas_accommodation NUMERIC(10, 2) NOT NULL DEFAULT 0,
  overseas_transportation NUMERIC(10, 2) NOT NULL DEFAULT 0,
  overseas_preparation_fee NUMERIC(10, 2) NOT NULL DEFAULT 0,
  overseas_accommodation_disabled BOOLEAN DEFAULT FALSE,
  overseas_transportation_disabled BOOLEAN DEFAULT FALSE,
  overseas_preparation_fee_disabled BOOLEAN DEFAULT FALSE
);

COMMENT ON TABLE public.user_allowance_settings IS '個々のユーザーの手当設定を格納するテーブル';

-- ユーザー通知設定テーブルの作成
CREATE TABLE IF NOT EXISTS public.user_notification_settings (
  user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  email_notifications BOOLEAN NOT NULL DEFAULT TRUE,
  push_notifications BOOLEAN NOT NULL DEFAULT TRUE,
  reminder_time TIME NOT NULL DEFAULT '09:00:00',
  approval_only BOOLEAN NOT NULL DEFAULT FALSE
);

COMMENT ON TABLE public.user_notification_settings IS '個々のユーザーの通知設定を格納するテーブル';

-- user_allowance_settingsのRLS設定
ALTER TABLE public.user_allowance_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own allowance settings"
  ON public.user_allowance_settings
  FOR ALL
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Admin users can manage all allowance settings"
  ON public.user_allowance_settings
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- user_notification_settingsのRLS設定
ALTER TABLE public.user_notification_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own notification settings"
  ON public.user_notification_settings
  FOR ALL
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Admin users can manage all notification settings"
  ON public.user_notification_settings
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );