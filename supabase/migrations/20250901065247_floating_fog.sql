/*
  # Supabase Storage バケット作成

  領収書や添付ファイル用のStorageバケットを作成し、
  適切なRLSポリシーを設定します。

  ## 作成されるバケット
  1. receipts - 領収書画像用
  2. documents - その他の添付ファイル用
  3. profile-avatars - プロファイル画像用

  ## セキュリティ
  - 認証済みユーザーのみアクセス可能
  - ファイルサイズ制限
  - ファイル形式制限
*/

-- ===================================
-- Storageバケットの作成
-- ===================================

-- 領収書用バケット
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'receipts',
  'receipts',
  false,
  10485760, -- 10MB
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf']
) ON CONFLICT (id) DO NOTHING;

-- 書類・添付ファイル用バケット
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'documents',
  'documents',
  false,
  52428800, -- 50MB
  ARRAY['application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'image/jpeg', 'image/png']
) ON CONFLICT (id) DO NOTHING;

-- プロファイル画像用バケット
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'profile-avatars',
  'profile-avatars',
  true,
  2097152, -- 2MB
  ARRAY['image/jpeg', 'image/png', 'image/webp']
) ON CONFLICT (id) DO NOTHING;

-- ===================================
-- Storage RLSポリシーの設定
-- ===================================

-- receipts バケットのポリシー
CREATE POLICY "Authenticated users can upload receipts"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'receipts');

CREATE POLICY "Users can view receipts for their applications"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'receipts' AND (
      -- 自分がアップロードしたファイル
      owner = auth.uid() OR
      -- 自分の申請に関連するファイル
      name LIKE (auth.uid()::text || '/%') OR
      -- 管理者は全て閲覧可能
      EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE id = auth.uid() AND role = 'admin'
      )
    )
  );

CREATE POLICY "Users can update own receipts"
  ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (bucket_id = 'receipts' AND owner = auth.uid());

CREATE POLICY "Users can delete own receipts"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (bucket_id = 'receipts' AND owner = auth.uid());

-- documents バケットのポリシー
CREATE POLICY "Authenticated users can upload documents"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'documents');

CREATE POLICY "Users can view documents for their applications"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'documents' AND (
      owner = auth.uid() OR
      EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE id = auth.uid() AND role = 'admin'
      )
    )
  );

CREATE POLICY "Users can update own documents"
  ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (bucket_id = 'documents' AND owner = auth.uid());

CREATE POLICY "Users can delete own documents"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (bucket_id = 'documents' AND owner = auth.uid());

-- profile-avatars バケットのポリシー
CREATE POLICY "Users can upload own profile avatar"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'profile-avatars' AND owner = auth.uid());

CREATE POLICY "Profile avatars are publicly viewable"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (bucket_id = 'profile-avatars');

CREATE POLICY "Users can update own profile avatar"
  ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (bucket_id = 'profile-avatars' AND owner = auth.uid());

CREATE POLICY "Users can delete own profile avatar"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (bucket_id = 'profile-avatars' AND owner = auth.uid());