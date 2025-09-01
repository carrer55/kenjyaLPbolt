/*
  # Create notifications table

  1. New Tables
    - `notifications`
      - `id` (uuid, primary key)
      - `user_id` (uuid, foreign key to profiles)
      - `type` (notification_type enum)
      - `title` (text, not null)
      - `message` (text, not null)
      - `timestamp` (timestamp)
      - `read` (boolean)
      - `category` (notification_category enum)
      - `related_application_id` (uuid, foreign key to applications)
      - `created_at` (timestamp)

  2. Security
    - Enable RLS on `notifications` table
    - Add policies for notification access
*/

-- Create notifications table
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

-- Add comments
COMMENT ON TABLE notifications IS 'ユーザーへの通知履歴を格納するテーブル';
COMMENT ON COLUMN notifications.user_id IS '通知対象のユーザーID';
COMMENT ON COLUMN notifications.type IS '通知の種別（メール、プッシュ）';
COMMENT ON COLUMN notifications.category IS '通知のカテゴリ';
COMMENT ON COLUMN notifications.related_application_id IS '関連する申請のID（任意）';

-- Enable RLS
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Create policies
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

CREATE POLICY "Admin users can view all notifications"
  ON notifications
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'admin'
    )
  );