/*
  # 書類関連のENUM型の作成

  1. New Types
    - `document_type` - 書類種別（business_report, expense_report, allowance_detail, travel_detail, gps_log, monthly_report, annual_report）
    - `document_status` - 書類ステータス（draft, submitted, approved, rejected）

  2. Security
    - No RLS needed for types
*/

-- 書類種別のENUM型
CREATE TYPE document_type AS ENUM ('business_report', 'expense_report', 'allowance_detail', 'travel_detail', 'gps_log', 'monthly_report', 'annual_report');

-- 書類ステータスのENUM型
CREATE TYPE document_status AS ENUM ('draft', 'submitted', 'approved', 'rejected');