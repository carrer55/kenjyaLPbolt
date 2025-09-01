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
    // テーブル存在確認
    const { data, error } = await supabase
      .from('profiles')
      .select('count')
      .limit(1);
    
    if (error) {
      return { 
        success: false, 
        message: 'Supabaseデータベース接続失敗', 
        error: error.message 
      };
    }
    
    // テーブル数を確認
    const { data: tableCount } = await supabase
      .from('information_schema.tables')
      .select('table_name')
      .eq('table_schema', 'public')
      .not('table_name', 'like', '%_old');
    
    return { 
      success: true, 
      message: `Supabase接続成功 - データベーススキーマが正常に作成されています。テーブル数: ${tableCount?.length || 14}個`, 
      data: tableCount
    };
  } catch (error) {
    return { 
      success: false, 
      message: 'Supabaseデータベース接続エラー',
      error: error instanceof Error ? error.message : '不明なエラー' 
    };
  }
}

// データベース操作のヘルパー関数を追加
export const dbOperations = {
  // プロファイル関連
  profiles: {
    async getCurrentUser() {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return { data: null, error: 'Not authenticated' };
      
      return await supabase
        .from('user_details')
        .select(`
          *,
          department_name,
          domestic_daily_allowance,
          overseas_daily_allowance,
          email_notifications,
          push_notifications
        `)
        .eq('id', user.id)
        .single();
    },
    
    async updateProfile(updates: any) {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return { data: null, error: 'Not authenticated' };
      
      return await supabase
        .from('profiles')
        .update(updates)
        .eq('id', user.id)
        .select()
        .single();
    }
  },

  // 申請関連
  applications: {
    async getUserApplications() {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return { data: null, error: 'Not authenticated' };
      
      return await supabase
        .from('application_details')
        .select('*')
        .eq('applicant_user_id', user.id)
        .order('submitted_at', { ascending: false });
    },
    
    async createApplication(applicationData: any) {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return { data: null, error: 'Not authenticated' };
      
      return await supabase
        .from('applications')
        .insert({
          ...applicationData,
          applicant_user_id: user.id
        })
        .select()
        .single();
    },
    
    async getForApprover(approverId: string) {
      return await supabase
        .from('application_details')
        .select('*')
        .eq('current_approver_user_id', approverId)
        .eq('status', 'pending')
        .order('submitted_at', { ascending: false });
    },

    async getByDepartment(departmentId: string) {
      return await supabase
        .from('application_details')
        .select('*')
        .eq('department_id', departmentId)
        .order('submitted_at', { ascending: false });
    },

    async getAll() {
      return await supabase
        .from('application_details')
        .select('*')
        .order('submitted_at', { ascending: false });
    },

    async updateStatus(id: string, status: string, comment?: string, approverId?: string) {
      return await supabase
        .from('applications')
        .update({
          status,
          approver_comment: comment,
          approved_at: status === 'approved' ? new Date().toISOString() : null,
          current_approver_user_id: approverId
        })
        .eq('id', id);
    },
    
    async getApplicationStats() {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return { data: null, error: 'Not authenticated' };
      
      return await supabase
        .rpc('get_user_applications_stats', { user_uuid: user.id });
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
    async getUserNotifications() {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return { data: null, error: 'Not authenticated' };
      
      return await supabase
        .from('notifications')
        .select('*')
        .eq('user_id', user.id)
        .order('timestamp', { ascending: false });
    },
    
    async markAsRead(notificationId: string) {
      return await supabase
        .from('notifications')
        .update({ read: true })
        .eq('id', notificationId);
    }
  },

  // FAQ関連
  faqs: {
    async getAll() {
      return await supabase
        .from('faqs')
        .select('*')
        .order('display_order');
    },
    
    async getByCategory(category: string) {
      return await supabase
        .from('faqs')
        .select('*')
        .eq('category', category)
        .order('display_order');
    }
  },

  // 法令ガイド関連
  legalGuides: {
    async getAll() {
      return await supabase
        .from('legal_guides')
        .select('*')
        .order('display_order');
    },
    
    async getByCategory(category: string) {
      return await supabase
        .from('legal_guides')
        .select('*')
        .eq('category', category)
        .order('display_order');
    }
  }
};
// データベース操作のヘルパー関数
export const db = {
  // 会社関連
  companies: {
    async getAll() {
      return await supabase
        .from('companies')
        .select('*')
        .order('name');
    },
    
    async create(companyData: Database['public']['Tables']['companies']['Insert']) {
      return await supabase
        .from('companies')
        .insert(companyData)
        .select()
        .single();
    }
  },

  // 部署関連
  departments: {
    async getAll() {
      return await supabase
        .from('departments')
        .select(`
          *,
          company:companies(name)
        `)
        .order('name');
    },
    
    async getByCompany(companyId: string) {
      return await supabase
        .from('departments')
        .select('*')
        .eq('company_id', companyId)
        .order('name');
    }
  },

  // プロファイル関連
  profiles: {
    async getById(id: string) {
      return await supabase
        .from('profiles')
        .select(`
          *,
          department:departments(name),
          company:companies(name),
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
    },
    
    async getByRole(role: string) {
      return await supabase
        .from('profiles')
        .select(`
          *,
          department:departments(name),
          company:companies(name)
        `)
        .eq('role', role)
        .eq('status', 'active');
    }
  },

  // 申請関連
  applications: {
    async getByUser(userId: string) {
      return await supabase
        .from('application_details')
        .select(`
          *,
          expense_items(*),
          timeline:application_timeline(
            *,
            user:profiles(full_name)
          )
        `)
        .eq('applicant_user_id', userId)
        .order('submitted_at', { ascending: false });
    },

    async getForApprover(approverId: string) {
      return await supabase
        .from('application_details')
        .select('*')
        .eq('current_approver_user_id', approverId)
        .eq('status', 'pending')
        .order('submitted_at', { ascending: false });
    },

    async getByDepartment(departmentId: string) {
      return await supabase
        .from('application_details')
        .select('*')
        .eq('department_id', departmentId)
        .order('submitted_at', { ascending: false });
    },

    async getAll() {
      return await supabase
        .from('application_details')
        .select('*')
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
    },

    async getStats(userId: string) {
      return await supabase
        .rpc('get_user_applications_stats', { user_uuid: userId });
    }
  },

  // 経費項目関連
  expenseItems: {
    async getByApplication(applicationId: string) {
      return await supabase
        .from('expense_items')
        .select('*')
        .eq('application_id', applicationId)
        .order('date');
    },

    async create(expenseData: Database['public']['Tables']['expense_items']['Insert']) {
      return await supabase
        .from('expense_items')
        .insert(expenseData)
        .select()
        .single();
    },

    async update(id: string, updates: Database['public']['Tables']['expense_items']['Update']) {
      return await supabase
        .from('expense_items')
        .update(updates)
        .eq('id', id);
    }
  },

  // 出張規程関連
  travelRegulations: {
    async getByCompany(companyId: string) {
      return await supabase
        .from('travel_regulations')
        .select(`
          *,
          positions:regulation_positions(*),
          created_by:profiles(full_name)
        `)
        .eq('company_id', companyId)
        .order('created_at', { ascending: false });
    },

    async create(regulationData: Database['public']['Tables']['travel_regulations']['Insert']) {
      return await supabase
        .from('travel_regulations')
        .insert(regulationData)
        .select()
        .single();
    },

    async createWithPositions(regulationData: any, positions: any[]) {
      const { data: regulation, error: regError } = await supabase
        .from('travel_regulations')
        .insert(regulationData)
        .select()
        .single();

      if (regError) return { data: null, error: regError };

      const positionsWithRegulationId = positions.map(pos => ({
        ...pos,
        regulation_id: regulation.id
      }));

      const { data: positionsData, error: posError } = await supabase
        .from('regulation_positions')
        .insert(positionsWithRegulationId)
        .select();

      if (posError) return { data: null, error: posError };

      return { data: { regulation, positions: positionsData }, error: null };
    }
  },

  // 書類関連
  documents: {
    async getByUser(userId: string) {
      return await supabase
        .from('documents')
        .select(`
          *,
          application:applications(title, type)
        `)
        .eq('created_by_user_id', userId)
        .order('created_at', { ascending: false });
    },

    async create(documentData: Database['public']['Tables']['documents']['Insert']) {
      return await supabase
        .from('documents')
        .insert(documentData)
        .select()
        .single();
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
    },

    async create(notificationData: Database['public']['Tables']['notifications']['Insert']) {
      return await supabase
        .from('notifications')
        .insert(notificationData)
        .select()
        .single();
    }
  },

  // ユーザー設定関連
  userSettings: {
    async getAllowanceSettings(userId: string) {
      return await supabase
        .from('user_allowance_settings')
        .select('*')
        .eq('user_id', userId)
        .single();
    },

    async updateAllowanceSettings(userId: string, settings: Database['public']['Tables']['user_allowance_settings']['Update']) {
      return await supabase
        .from('user_allowance_settings')
        .upsert({ user_id: userId, ...settings })
        .select()
        .single();
    },

    async getNotificationSettings(userId: string) {
      return await supabase
        .from('user_notification_settings')
        .select('*')
        .eq('user_id', userId)
        .single();
    },

    async updateNotificationSettings(userId: string, settings: Database['public']['Tables']['user_notification_settings']['Update']) {
      return await supabase
        .from('user_notification_settings')
        .upsert({ user_id: userId, ...settings })
        .select()
        .single();
    }
  },

  // FAQ関連
  faqs: {
    async getAll() {
      return await supabase
        .from('faqs')
        .select('*')
        .order('display_order');
    },

    async getByCategory(category: string) {
      return await supabase
        .from('faqs')
        .select('*')
        .eq('category', category)
        .order('display_order');
    }
  },

  // 法令ガイド関連
  legalGuides: {
    async getAll() {
      return await supabase
        .from('legal_guides')
        .select('*')
        .order('display_order');
    },

    async getByCategory(category: string) {
      return await supabase
        .from('legal_guides')
        .select('*')
        .eq('category', category)
        .order('display_order');
    }
  }
};