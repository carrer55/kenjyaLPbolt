import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://bjoxgogehtfibmsbdqmo.supabase.co';
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseAnonKey) {
  throw new Error('Missing Supabase environment variables');
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

// 接続テスト関数
export async function testSupabaseConnection() {
  try {
    const { data, error } = await supabase
      .from('_test_connection')
      .select('*')
      .limit(1);
    
    if (error && error.code === 'PGRST116') {
      // テーブルが存在しない場合は正常（接続は成功）
      return { success: true, message: 'Supabase接続成功' };
    }
    
    if (error) {
      return { success: false, error: error.message };
    }
    
    return { success: true, message: 'Supabase接続成功', data };
  } catch (error) {
    return { 
      success: false, 
      error: error instanceof Error ? error.message : '不明なエラー' 
    };
  }
}