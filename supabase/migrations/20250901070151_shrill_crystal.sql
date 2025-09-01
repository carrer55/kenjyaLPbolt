/*
  # Create user settings tables

  1. New Tables
    - `user_allowance_settings`
      - User-specific allowance configurations
    - `user_notification_settings`
      - User-specific notification preferences

  2. Security
    - Enable RLS on both tables
    - Add policies for user settings access
*/

-- Create user_allowance_settings table
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

-- Add comments for user_allowance_settings
COMMENT ON TABLE user_allowance_settings IS '個々のユーザーの手当設定を格納するテーブル';
COMMENT ON COLUMN user_allowance_settings.domestic_daily_allowance IS '国内出張日当';
COMMENT ON COLUMN user_allowance_settings.domestic_accommodation IS '国内宿泊料';
COMMENT ON COLUMN user_allowance_settings.domestic_transportation IS '国内交通費';
COMMENT ON COLUMN user_allowance_settings.overseas_daily_allowance IS '海外出張日当';
COMMENT ON COLUMN user_allowance_settings.overseas_accommodation IS '海外宿泊料';
COMMENT ON COLUMN user_allowance_settings.overseas_transportation IS '海外交通費';
COMMENT ON COLUMN user_allowance_settings.overseas_preparation_fee IS '海外出張支度料';

-- Create user_notification_settings table
CREATE TABLE IF NOT EXISTS user_notification_settings (
  user_id uuid PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  email_notifications boolean NOT NULL DEFAULT true,
  push_notifications boolean NOT NULL DEFAULT true,
  reminder_time time NOT NULL DEFAULT '09:00:00',
  approval_only boolean NOT NULL DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Add comments for user_notification_settings
COMMENT ON TABLE user_notification_settings IS '個々のユーザーの通知設定を格納するテーブル';
COMMENT ON COLUMN user_notification_settings.email_notifications IS 'メール通知の有効/無効';
COMMENT ON COLUMN user_notification_settings.push_notifications IS 'プッシュ通知の有効/無効';
COMMENT ON COLUMN user_notification_settings.reminder_time IS 'リマインド通知の時刻';
COMMENT ON COLUMN user_notification_settings.approval_only IS '承認通知のみ受信するかどうか';

-- Enable RLS
ALTER TABLE user_allowance_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_notification_settings ENABLE ROW LEVEL SECURITY;

-- Create policies for user_allowance_settings
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

CREATE POLICY "Admin users can view all allowance settings"
  ON user_allowance_settings
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'admin'
    )
  );

-- Create policies for user_notification_settings
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

CREATE POLICY "Admin users can view all notification settings"
  ON user_notification_settings
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'admin'
    )
  );

-- Create updated_at triggers
CREATE TRIGGER update_user_allowance_settings_updated_at
  BEFORE UPDATE ON user_allowance_settings
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_notification_settings_updated_at
  BEFORE UPDATE ON user_notification_settings
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();