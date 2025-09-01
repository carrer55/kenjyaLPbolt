// Supabaseで生成される型定義ファイル
// 実際の実装では `supabase gen types typescript --project-id YOUR_PROJECT_ID` で生成

export interface Database {
  public: {
    Tables: {
      companies: {
        Row: {
          id: string;
          name: string;
          address: string | null;
          representative: string | null;
          phone_number: string | null;
          email: string | null;
          established_date: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          name: string;
          address?: string | null;
          representative?: string | null;
          phone_number?: string | null;
          email?: string | null;
          established_date?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          name?: string;
          address?: string | null;
          representative?: string | null;
          phone_number?: string | null;
          email?: string | null;
          established_date?: string | null;
          created_at?: string;
          updated_at?: string;
        };
      };
      departments: {
        Row: {
          id: string;
          company_id: string;
          name: string;
          created_at: string;
        };
        Insert: {
          id?: string;
          company_id: string;
          name: string;
          created_at?: string;
        };
        Update: {
          id?: string;
          company_id?: string;
          name?: string;
          created_at?: string;
        };
      };
      profiles: {
        Row: {
          id: string;
          full_name: string | null;
          company_id: string | null;
          company_name: string | null;
          position: string | null;
          phone_number: string | null;
          role: 'admin' | 'department_admin' | 'approver' | 'general_user';
          plan: 'Free' | 'Pro' | 'Enterprise';
          department_id: string | null;
          created_at: string;
          updated_at: string;
          invited_by_user_id: string | null;
          status: 'active' | 'invited' | 'inactive';
          last_login_at: string | null;
          onboarding_completed: boolean;
        };
        Insert: {
          id: string;
          full_name?: string | null;
          company_id?: string | null;
          company_name?: string | null;
          position?: string | null;
          phone_number?: string | null;
          role?: 'admin' | 'department_admin' | 'approver' | 'general_user';
          plan?: 'Free' | 'Pro' | 'Enterprise';
          department_id?: string | null;
          created_at?: string;
          updated_at?: string;
          invited_by_user_id?: string | null;
          status?: 'active' | 'invited' | 'inactive';
          last_login_at?: string | null;
          onboarding_completed?: boolean;
        };
        Update: {
          id?: string;
          full_name?: string | null;
          company_id?: string | null;
          company_name?: string | null;
          position?: string | null;
          phone_number?: string | null;
          role?: 'admin' | 'department_admin' | 'approver' | 'general_user';
          plan?: 'Free' | 'Pro' | 'Enterprise';
          department_id?: string | null;
          created_at?: string;
          updated_at?: string;
          invited_by_user_id?: string | null;
          status?: 'active' | 'invited' | 'inactive';
          last_login_at?: string | null;
          onboarding_completed?: boolean;
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
          estimated_daily_allowance: number | null;
          estimated_transportation: number | null;
          estimated_accommodation: number | null;
          created_at: string;
          updated_at: string;
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
          estimated_daily_allowance?: number | null;
          estimated_transportation?: number | null;
          estimated_accommodation?: number | null;
          created_at?: string;
          updated_at?: string;
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
          estimated_daily_allowance?: number | null;
          estimated_transportation?: number | null;
          estimated_accommodation?: number | null;
          created_at?: string;
          updated_at?: string;
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
          created_at: string;
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
          created_at?: string;
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
          created_at?: string;
        };
      };
      application_timeline: {
        Row: {
          id: string;
          application_id: string;
          timestamp: string;
          action: string;
          status_change: 'draft' | 'pending' | 'returned' | 'approved' | 'rejected' | 'on_hold' | 'submitted' | null;
          user_id: string;
          comment: string | null;
          created_at: string;
        };
        Insert: {
          id?: string;
          application_id: string;
          timestamp?: string;
          action: string;
          status_change?: 'draft' | 'pending' | 'returned' | 'approved' | 'rejected' | 'on_hold' | 'submitted' | null;
          user_id: string;
          comment?: string | null;
          created_at?: string;
        };
        Update: {
          id?: string;
          application_id?: string;
          timestamp?: string;
          action?: string;
          status_change?: 'draft' | 'pending' | 'returned' | 'approved' | 'rejected' | 'on_hold' | 'submitted' | null;
          user_id?: string;
          comment?: string | null;
          created_at?: string;
        };
      };
      travel_regulations: {
        Row: {
          id: string;
          company_id: string;
          company_name: string;
          company_address: string | null;
          company_representative: string | null;
          established_date: string | null;
          revision: number;
          version: string;
          created_at: string;
          created_by_user_id: string;
          updated_at: string;
          status: 'active' | 'draft' | 'archived';
          distance_threshold_km: number | null;
          is_transportation_real_expense: boolean;
          is_accommodation_real_expense: boolean;
          use_preparation_fee: boolean;
          full_text_content: string | null;
          custom_articles: any | null;
        };
        Insert: {
          id?: string;
          company_id: string;
          company_name: string;
          company_address?: string | null;
          company_representative?: string | null;
          established_date?: string | null;
          revision?: number;
          version: string;
          created_at?: string;
          created_by_user_id: string;
          updated_at?: string;
          status?: 'active' | 'draft' | 'archived';
          distance_threshold_km?: number | null;
          is_transportation_real_expense?: boolean;
          is_accommodation_real_expense?: boolean;
          use_preparation_fee?: boolean;
          full_text_content?: string | null;
          custom_articles?: any | null;
        };
        Update: {
          id?: string;
          company_id?: string;
          company_name?: string;
          company_address?: string | null;
          company_representative?: string | null;
          established_date?: string | null;
          revision?: number;
          version?: string;
          created_at?: string;
          created_by_user_id?: string;
          updated_at?: string;
          status?: 'active' | 'draft' | 'archived';
          distance_threshold_km?: number | null;
          is_transportation_real_expense?: boolean;
          is_accommodation_real_expense?: boolean;
          use_preparation_fee?: boolean;
          full_text_content?: string | null;
          custom_articles?: any | null;
        };
      };
      regulation_positions: {
        Row: {
          id: string;
          regulation_id: string;
          position_name: string;
          domestic_daily_allowance: number;
          domestic_accommodation: number;
          domestic_transportation: number;
          overseas_daily_allowance: number;
          overseas_accommodation: number;
          overseas_transportation: number;
          overseas_preparation_fee: number;
          created_at: string;
        };
        Insert: {
          id?: string;
          regulation_id: string;
          position_name: string;
          domestic_daily_allowance?: number;
          domestic_accommodation?: number;
          domestic_transportation?: number;
          overseas_daily_allowance?: number;
          overseas_accommodation?: number;
          overseas_transportation?: number;
          overseas_preparation_fee?: number;
          created_at?: string;
        };
        Update: {
          id?: string;
          regulation_id?: string;
          position_name?: string;
          domestic_daily_allowance?: number;
          domestic_accommodation?: number;
          domestic_transportation?: number;
          overseas_daily_allowance?: number;
          overseas_accommodation?: number;
          overseas_transportation?: number;
          overseas_preparation_fee?: number;
          created_at?: string;
        };
      };
      documents: {
        Row: {
          id: string;
          application_id: string | null;
          type: 'business_report' | 'expense_report' | 'allowance_detail' | 'travel_detail' | 'gps_log' | 'monthly_report' | 'annual_report';
          title: string;
          created_by_user_id: string;
          created_at: string;
          updated_at: string;
          status: 'draft' | 'submitted' | 'approved' | 'rejected';
          content_json: any | null;
          attachments_urls: string[] | null;
          file_url: string | null;
        };
        Insert: {
          id?: string;
          application_id?: string | null;
          type: 'business_report' | 'expense_report' | 'allowance_detail' | 'travel_detail' | 'gps_log' | 'monthly_report' | 'annual_report';
          title: string;
          created_by_user_id: string;
          created_at?: string;
          updated_at?: string;
          status?: 'draft' | 'submitted' | 'approved' | 'rejected';
          content_json?: any | null;
          attachments_urls?: string[] | null;
          file_url?: string | null;
        };
        Update: {
          id?: string;
          application_id?: string | null;
          type?: 'business_report' | 'expense_report' | 'allowance_detail' | 'travel_detail' | 'gps_log' | 'monthly_report' | 'annual_report';
          title?: string;
          created_by_user_id?: string;
          created_at?: string;
          updated_at?: string;
          status?: 'draft' | 'submitted' | 'approved' | 'rejected';
          content_json?: any | null;
          attachments_urls?: string[] | null;
          file_url?: string | null;
        };
      };
      notifications: {
        Row: {
          id: string;
          user_id: string;
          type: 'email' | 'push';
          title: string;
          message: string;
          timestamp: string;
          read: boolean;
          category: 'approval' | 'reminder' | 'system' | 'update';
          related_application_id: string | null;
          created_at: string;
        };
        Insert: {
          id?: string;
          user_id: string;
          type: 'email' | 'push';
          title: string;
          message: string;
          timestamp?: string;
          read?: boolean;
          category: 'approval' | 'reminder' | 'system' | 'update';
          related_application_id?: string | null;
          created_at?: string;
        };
        Update: {
          id?: string;
          user_id?: string;
          type?: 'email' | 'push';
          title?: string;
          message?: string;
          timestamp?: string;
          read?: boolean;
          category?: 'approval' | 'reminder' | 'system' | 'update';
          related_application_id?: string | null;
          created_at?: string;
        };
      };
      user_allowance_settings: {
        Row: {
          user_id: string;
          domestic_daily_allowance: number;
          domestic_accommodation: number;
          domestic_transportation: number;
          domestic_accommodation_disabled: boolean;
          domestic_transportation_disabled: boolean;
          overseas_daily_allowance: number;
          overseas_accommodation: number;
          overseas_transportation: number;
          overseas_preparation_fee: number;
          overseas_accommodation_disabled: boolean;
          overseas_transportation_disabled: boolean;
          overseas_preparation_fee_disabled: boolean;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          user_id: string;
          domestic_daily_allowance?: number;
          domestic_accommodation?: number;
          domestic_transportation?: number;
          domestic_accommodation_disabled?: boolean;
          domestic_transportation_disabled?: boolean;
          overseas_daily_allowance?: number;
          overseas_accommodation?: number;
          overseas_transportation?: number;
          overseas_preparation_fee?: number;
          overseas_accommodation_disabled?: boolean;
          overseas_transportation_disabled?: boolean;
          overseas_preparation_fee_disabled?: boolean;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          user_id?: string;
          domestic_daily_allowance?: number;
          domestic_accommodation?: number;
          domestic_transportation?: number;
          domestic_accommodation_disabled?: boolean;
          domestic_transportation_disabled?: boolean;
          overseas_daily_allowance?: number;
          overseas_accommodation?: number;
          overseas_transportation?: number;
          overseas_preparation_fee?: number;
          overseas_accommodation_disabled?: boolean;
          overseas_transportation_disabled?: boolean;
          overseas_preparation_fee_disabled?: boolean;
          created_at?: string;
          updated_at?: string;
        };
      };
      user_notification_settings: {
        Row: {
          user_id: string;
          email_notifications: boolean;
          push_notifications: boolean;
          reminder_time: string;
          approval_only: boolean;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          user_id: string;
          email_notifications?: boolean;
          push_notifications?: boolean;
          reminder_time?: string;
          approval_only?: boolean;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          user_id?: string;
          email_notifications?: boolean;
          push_notifications?: boolean;
          reminder_time?: string;
          approval_only?: boolean;
          created_at?: string;
          updated_at?: string;
        };
      };
      faqs: {
        Row: {
          id: string;
          category: string;
          question: string;
          answer: string;
          display_order: number;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          category: string;
          question: string;
          answer: string;
          display_order?: number;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          category?: string;
          question?: string;
          answer?: string;
          display_order?: number;
          created_at?: string;
          updated_at?: string;
        };
      };
      legal_guides: {
        Row: {
          id: string;
          title: string;
          description: string;
          url: string;
          category: 'law' | 'regulation' | 'tax' | 'guide';
          importance: 'high' | 'medium' | 'low';
          last_updated: string;
          display_order: number;
          created_at: string;
        };
        Insert: {
          id?: string;
          title: string;
          description: string;
          url: string;
          category: 'law' | 'regulation' | 'tax' | 'guide';
          importance: 'high' | 'medium' | 'low';
          last_updated: string;
          display_order?: number;
          created_at?: string;
        };
        Update: {
          id?: string;
          title?: string;
          description?: string;
          url?: string;
          category?: 'law' | 'regulation' | 'tax' | 'guide';
          importance?: 'high' | 'medium' | 'low';
          last_updated?: string;
          display_order?: number;
          created_at?: string;
        };
      };
    };
    Views: {
      application_details: {
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
          estimated_daily_allowance: number | null;
          estimated_transportation: number | null;
          estimated_accommodation: number | null;
          created_at: string;
          updated_at: string;
          applicant_name: string | null;
          department_name: string | null;
          approver_name: string | null;
          company_name: string | null;
        };
      };
      user_details: {
        Row: {
          id: string;
          full_name: string | null;
          company_id: string | null;
          company_name: string | null;
          position: string | null;
          phone_number: string | null;
          role: 'admin' | 'department_admin' | 'approver' | 'general_user';
          plan: 'Free' | 'Pro' | 'Enterprise';
          department_id: string | null;
          created_at: string;
          updated_at: string;
          invited_by_user_id: string | null;
          status: 'active' | 'invited' | 'inactive';
          last_login_at: string | null;
          onboarding_completed: boolean;
          department_name: string | null;
          domestic_daily_allowance: number | null;
          overseas_daily_allowance: number | null;
          email_notifications: boolean | null;
          push_notifications: boolean | null;
        };
      };
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
      handle_new_user: {
        Args: Record<PropertyKey, never>;
        Returns: undefined;
      };
      update_updated_at_column: {
        Args: Record<PropertyKey, never>;
        Returns: undefined;
      };
      log_application_status_change: {
        Args: Record<PropertyKey, never>;
        Returns: undefined;
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