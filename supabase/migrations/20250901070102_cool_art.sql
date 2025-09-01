/*
  # Create application_timeline table

  1. New Tables
    - `application_timeline`
      - `id` (uuid, primary key)
      - `application_id` (uuid, foreign key to applications)
      - `timestamp` (timestamp)
      - `action` (text, not null)
      - `status_change` (application_status enum)
      - `user_id` (uuid, foreign key to profiles)
      - `comment` (text)
      - `created_at` (timestamp)

  2. Security
    - Enable RLS on `application_timeline` table
    - Add policies for timeline access based on application ownership
*/

-- Create application_timeline table
CREATE TABLE IF NOT EXISTS application_timeline (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id uuid NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  timestamp timestamptz DEFAULT now(),
  action text NOT NULL,
  status_change application_status,
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  comment text,
  created_at timestamptz DEFAULT now()
);

-- Add comments
COMMENT ON TABLE application_timeline IS '申請の承認履歴やステータス変更を記録するテーブル';
COMMENT ON COLUMN application_timeline.action IS '実行されたアクション（例：申請提出、部長承認、経理確認中）';
COMMENT ON COLUMN application_timeline.status_change IS '変更後のステータス';
COMMENT ON COLUMN application_timeline.user_id IS 'アクションを実行したユーザーのID';

-- Enable RLS
ALTER TABLE application_timeline ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view own application timeline"
  ON application_timeline
  FOR SELECT
  TO authenticated
  USING (
    application_id IN (
      SELECT id FROM applications 
      WHERE applicant_user_id = auth.uid()
    )
  );

CREATE POLICY "Approvers can view assigned application timeline"
  ON application_timeline
  FOR SELECT
  TO authenticated
  USING (
    application_id IN (
      SELECT id FROM applications 
      WHERE current_approver_user_id = auth.uid()
    )
  );

CREATE POLICY "Admin users can view all application timeline"
  ON application_timeline
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'admin'
    )
  );

CREATE POLICY "Authenticated users can create timeline entries"
  ON application_timeline
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- Function to automatically log application status changes
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
        WHEN 'submitted' THEN '提出'
        ELSE 'ステータス変更'
      END,
      NEW.status,
      auth.uid(),
      NEW.approver_comment
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for automatic status change logging
CREATE TRIGGER log_application_status_change_trigger
  AFTER UPDATE ON applications
  FOR EACH ROW
  EXECUTE FUNCTION log_application_status_change();