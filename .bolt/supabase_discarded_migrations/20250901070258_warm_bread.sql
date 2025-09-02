/*
  # Create Supabase Storage buckets

  1. New Buckets
    - `receipts` - For receipt images and documents
    - `documents` - For generated documents (PDF, Word)
    - `profile-avatars` - For user profile images

  2. Security
    - Enable RLS on all buckets
    - Add policies for file access based on user authentication
*/

-- Create storage buckets
INSERT INTO storage.buckets (id, name, public) VALUES 
  ('receipts', 'receipts', false),
  ('documents', 'documents', false),
  ('profile-avatars', 'profile-avatars', false)
ON CONFLICT (id) DO NOTHING;

-- Create policies for receipts bucket
CREATE POLICY "Authenticated users can upload receipts"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'receipts');

CREATE POLICY "Authenticated users can view receipts"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (bucket_id = 'receipts');

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

-- Create policies for documents bucket
CREATE POLICY "Authenticated users can upload documents"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'documents');

CREATE POLICY "Authenticated users can view documents"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (bucket_id = 'documents');

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

-- Create policies for profile-avatars bucket
CREATE POLICY "Authenticated users can upload profile avatars"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'profile-avatars');

CREATE POLICY "Authenticated users can view profile avatars"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (bucket_id = 'profile-avatars');

CREATE POLICY "Users can update own profile avatars"
  ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (bucket_id = 'profile-avatars' AND owner = auth.uid());

CREATE POLICY "Users can delete own profile avatars"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (bucket_id = 'profile-avatars' AND owner = auth.uid());