/*
  # ユーザー関連のENUM型の作成

  1. New Types
    - `user_role` - ユーザーの役割（admin, department_admin, approver, general_user）
    - `user_plan` - ユーザーの契約プラン（Free, Pro, Enterprise）
    - `user_status` - ユーザーのステータス（active, invited, inactive）

  2. Security
    - No RLS needed for types
*/

-- ユーザー役割のENUM型
CREATE TYPE user_role AS ENUM ('admin', 'department_admin', 'approver', 'general_user');

-- ユーザープランのENUM型
CREATE TYPE user_plan AS ENUM ('Free', 'Pro', 'Enterprise');

-- ユーザーステータスのENUM型
CREATE TYPE user_status AS ENUM ('active', 'invited', 'inactive');