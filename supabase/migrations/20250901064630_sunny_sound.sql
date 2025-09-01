/*
  # 申請関連のENUM型の作成

  1. New Types
    - `application_type` - 申請種別（business_trip, expense）
    - `application_status` - 申請ステータス（draft, pending, returned, approved, rejected, on_hold, submitted）

  2. Security
    - No RLS needed for types
*/

-- 申請種別のENUM型
CREATE TYPE application_type AS ENUM ('business_trip', 'expense');

-- 申請ステータスのENUM型
CREATE TYPE application_status AS ENUM ('draft', 'pending', 'returned', 'approved', 'rejected', 'on_hold', 'submitted');