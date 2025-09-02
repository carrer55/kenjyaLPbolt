/*
  # 通知関連のENUM型の作成

  1. New Types
    - `notification_type` - 通知種別（email, push）
    - `notification_category` - 通知カテゴリ（approval, reminder, system, update）

  2. Security
    - No RLS needed for types
*/

-- 通知種別のENUM型
CREATE TYPE notification_type AS ENUM ('email', 'push');

-- 通知カテゴリのENUM型
CREATE TYPE notification_category AS ENUM ('approval', 'reminder', 'system', 'update');