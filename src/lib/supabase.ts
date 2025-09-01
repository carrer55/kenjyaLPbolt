import { createClient } from '@supabase/supabase-js';
import type { Database } from './database.types';

const supabaseUrl = 'https://bjoxgogehtfibmsbdqmo.supabase.co';
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseAnonKey) {
  throw new Error('Missing Supabase environment variables');
}

export const supabase = createClient<Database>(supabaseUrl, supabaseAnonKey);

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

// データベース操作のヘルパー関数
export const db = {
  // プロファイル関連
  profiles: {
    async getById(id: string) {
      return await supabase
        .from('profiles')
        .select(`
          *,
          department:departments(name),
          invited_by:profiles!invited_by_user_id(full_name)
        `)
        .eq('id', id)
        .single();
    },
    
    async update(id: string, updates: any) {
      return await supabase
        .from('profiles')
        .update(updates)
        .eq('id', id);
    }
  },

  // 申請関連
  applications: {
    async getByUser(userId: string) {
      return await supabase
        .from('applications')
        .select(`
          *,
          applicant:profiles!applicant_user_id(full_name),
          department:departments(name),
          expense_items(*),
          timeline:application_timeline(*)
        `)
        .eq('applicant_user_id', userId)
        .order('submitted_at', { ascending: false });
    },

    async create(applicationData: any) {
      return await supabase
        .from('applications')
        .insert(applicationData)
        .select()
        .single();
    },

    async updateStatus(id: string, status: string, comment?: string) {
      return await supabase
        .from('applications')
        .update({
          status,
          approver_comment: comment,
          approved_at: status === 'approved' ? new Date().toISOString() : null
        })
        .eq('id', id);
    }
  },

  // 部署関連
  departments: {
    async getAll() {
      return await supabase
        .from('departments')
        .select('*')
        .order('name');
    }
  },

  // 通知関連
  notifications: {
    async getByUser(userId: string) {
      return await supabase
        .from('notifications')
        .select('*')
        .eq('user_id', userId)
        .order('timestamp', { ascending: false });
    },

    async markAsRead(id: string) {
      return await supabase
        .from('notifications')
        .update({ read: true })
        .eq('id', id);
    }
  }
};