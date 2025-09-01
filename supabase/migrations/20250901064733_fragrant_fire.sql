/*
  # 通知テーブルの作成

  1. New Tables
    - `notifications`
      - `id` (uuid, primary key)
      - `user_id` (uuid) - 通知対象ユーザーID
      - `type` (notification_type) - 通知種別
      - `title` (text) - 通知タイトル
      - `message` (text) - 通知メッセージ
      - `timestamp` (timestamp) - 通知日時
      - `read` (boolean) - 既読フラグ
      - `category` (notification_category) - 通知カテゴリ
      - `related_application_id` (uuid) - 関連申請ID

  2. Security
    - Enable RLS on `notifications` table
    - Add policy for users to read their own notifications
    - Add policy for system to create notifications
*/

-- 通知テーブルの作成
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type notification_type NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  read BOOLEAN DEFAULT FALSE,
  category notification_category NOT NULL,
  related_application_id UUID REFERENCES public.applications(id) ON DELETE SET NULL
);

COMMENT ON TABLE public.notifications IS 'ユーザーへの通知履歴を格納するテーブル';

-- RLSを有効化
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- ユーザーは自身の通知のみ参照・更新可能
CREATE POLICY "Users can read own notifications"
  ON public.notifications
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can update own notifications"
  ON public.notifications
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid());

-- システム（管理者）は通知を作成可能
CREATE POLICY "System can create notifications"
  ON public.notifications
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- 管理者は全ての通知を管理可能
CREATE POLICY "Admin users can manage all notifications"
  ON public.notifications
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );