// Supabaseで生成される型定義ファイル
// 実際の実装では `supabase gen types typescript --project-id YOUR_PROJECT_ID` で生成

export interface Database {
  public: {
    Tables: {
      departments: {
        Row: {
          id: string;
          name: string;
          created_at: string;
        };
        Insert: {
          id?: string;
          name: string;
          created_at?: string;
        };
        Update: {
          id?: string;
          name?: string;
          created_at?: string;
        };
      };
      profiles: {
        Row: {
          id: string;
          full_name: string | null;
          company_name: string | null;
          position: string | null;
          phone_number: string | null;
          role: 'admin' | 'department_admin' | 'approver' | 'general_user';
          plan: 'Free' | 'Pro' | 'Enterprise';
          department_id: string | null;
          created_at: string;
          invited_by_user_id: string | null;
          status: 'active' | 'invited' | 'inactive';
          last_login_at: string | null;
        };
        Insert: {
          id: string;
          full_name?: string | null;
          company_name?: string | null;
          position?: string | null;
          phone_number?: string | null;
          role?: 'admin' | 'department_admin' | 'approver' | 'general_user';
          plan?: 'Free' | 'Pro' | 'Enterprise';
          department_id?: string | null;
          created_at?: string;
          invited_by_user_id?: string | null;
          status?: 'active' | 'invited' | 'inactive';
          last_login_at?: string | null;
        };
        Update: {
          id?: string;
          full_name?: string | null;
          company_name?: string | null;
          position?: string | null;
          phone_number?: string | null;
          role?: 'admin' | 'department_admin' | 'approver' | 'general_user';
          plan?: 'Free' | 'Pro' | 'Enterprise';
          department_id?: string | null;
          created_at?: string;
          invited_by_user_id?: string | null;
          status?: 'active' | 'invited' | 'inactive';
          last_login_at?: string | null;
        };
      };
      applications: {
        Row: {
          id: string;
          type: 'business_trip' | 'expense';
          title: string;
          applicant_user_id: string;
          department_id: string;
          amount: number | null;
          submitted_at: string;
          status: 'draft' | 'pending' | 'returned' | 'approved' | 'rejected' | 'on_hold' | 'submitted';
          current_approver_user_id: string | null;
          purpose: string | null;
          start_date: string | null;
          end_date: string | null;
          location: string | null;
          visit_target: string | null;
          companions: string | null;
          approved_at: string | null;
          approver_comment: string | null;
        };
        Insert: {
          id?: string;
          type: 'business_trip' | 'expense';
          title: string;
          applicant_user_id: string;
          department_id: string;
          amount?: number | null;
          submitted_at?: string;
          status?: 'draft' | 'pending' | 'returned' | 'approved' | 'rejected' | 'on_hold' | 'submitted';
          current_approver_user_id?: string | null;
          purpose?: string | null;
          start_date?: string | null;
          end_date?: string | null;
          location?: string | null;
          visit_target?: string | null;
          companions?: string | null;
          approved_at?: string | null;
          approver_comment?: string | null;
        };
        Update: {
          id?: string;
          type?: 'business_trip' | 'expense';
          title?: string;
          applicant_user_id?: string;
          department_id?: string;
          amount?: number | null;
          submitted_at?: string;
          status?: 'draft' | 'pending' | 'returned' | 'approved' | 'rejected' | 'on_hold' | 'submitted';
          current_approver_user_id?: string | null;
          purpose?: string | null;
          start_date?: string | null;
          end_date?: string | null;
          location?: string | null;
          visit_target?: string | null;
          companions?: string | null;
          approved_at?: string | null;
          approver_comment?: string | null;
        };
      };
      expense_items: {
        Row: {
          id: string;
          application_id: string;
          category: string;
          date: string;
          amount: number;
          description: string | null;
          store: string | null;
          receipt_url: string | null;
          ocr_processed: boolean;
          ocr_result_store: string | null;
          ocr_result_date: string | null;
          ocr_result_amount: number | null;
          ocr_result_confidence: number | null;
        };
        Insert: {
          id?: string;
          application_id: string;
          category: string;
          date: string;
          amount: number;
          description?: string | null;
          store?: string | null;
          receipt_url?: string | null;
          ocr_processed?: boolean;
          ocr_result_store?: string | null;
          ocr_result_date?: string | null;
          ocr_result_amount?: number | null;
          ocr_result_confidence?: number | null;
        };
        Update: {
          id?: string;
          application_id?: string;
          category?: string;
          date?: string;
          amount?: number;
          description?: string | null;
          store?: string | null;
          receipt_url?: string | null;
          ocr_processed?: boolean;
          ocr_result_store?: string | null;
          ocr_result_date?: string | null;
          ocr_result_amount?: number | null;
          ocr_result_confidence?: number | null;
        };
      };
      // 他のテーブルの型定義も同様に追加...
    };
    Views: {
      [_ in never]: never;
    };
    Functions: {
      get_user_applications_stats: {
        Args: {
          user_uuid: string;
        };
        Returns: {
          total_applications: number;
          pending_applications: number;
          approved_applications: number;
          total_amount: number;
          current_month_amount: number;
        }[];
      };
    };
    Enums: {
      user_role: 'admin' | 'department_admin' | 'approver' | 'general_user';
      user_plan: 'Free' | 'Pro' | 'Enterprise';
      user_status: 'active' | 'invited' | 'inactive';
      application_type: 'business_trip' | 'expense';
      application_status: 'draft' | 'pending' | 'returned' | 'approved' | 'rejected' | 'on_hold' | 'submitted';
      regulation_status: 'active' | 'draft' | 'archived';
      document_type: 'business_report' | 'expense_report' | 'allowance_detail' | 'travel_detail' | 'gps_log' | 'monthly_report' | 'annual_report';
      document_status: 'draft' | 'submitted' | 'approved' | 'rejected';
      notification_type: 'email' | 'push';
      notification_category: 'approval' | 'reminder' | 'system' | 'update';
      legal_category: 'law' | 'regulation' | 'tax' | 'guide';
      importance_level: 'high' | 'medium' | 'low';
    };
  };
}