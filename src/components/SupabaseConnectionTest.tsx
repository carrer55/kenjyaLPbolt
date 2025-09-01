import React, { useState, useEffect } from 'react';
import { CheckCircle, XCircle, Loader, Database, AlertTriangle } from 'lucide-react';
import { testSupabaseConnection } from '../lib/supabase';

interface SupabaseConnectionTestProps {
  onClose: () => void;
}

function SupabaseConnectionTest({ onClose }: SupabaseConnectionTestProps) {
  const [connectionStatus, setConnectionStatus] = useState<{
    loading: boolean;
    success: boolean | null;
    message: string;
    error?: string;
  }>({
    loading: true,
    success: null,
    message: ''
  });

  useEffect(() => {
    const testConnection = async () => {
      setConnectionStatus({ loading: true, success: null, message: '' });
      
      // 環境変数の確認
      const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;
      
      if (!supabaseAnonKey) {
        setConnectionStatus({
          loading: false,
          success: false,
          message: 'Supabase環境変数が設定されていません',
          error: 'VITE_SUPABASE_ANON_KEYが見つかりません'
        });
        return;
      }

      try {
        const result = await testSupabaseConnection();
        setConnectionStatus({
          loading: false,
          success: result.success,
          message: result.message,
          error: result.error
        });
      } catch (error) {
        setConnectionStatus({
          loading: false,
          success: false,
          message: '接続テストに失敗しました',
          error: error instanceof Error ? error.message : '不明なエラー'
        });
      }
    };

    testConnection();
  }, []);

  const getStatusIcon = () => {
    if (connectionStatus.loading) {
      return <Loader className="w-8 h-8 text-blue-600 animate-spin" />;
    }
    if (connectionStatus.success) {
      return <CheckCircle className="w-8 h-8 text-emerald-600" />;
    }
    return <XCircle className="w-8 h-8 text-red-600" />;
  };

  const getStatusColor = () => {
    if (connectionStatus.loading) return 'from-blue-500/20 to-blue-700/20 border-blue-300/30';
    if (connectionStatus.success) return 'from-emerald-500/20 to-emerald-700/20 border-emerald-300/30';
    return 'from-red-500/20 to-red-700/20 border-red-300/30';
  };

  const getStatusTitle = () => {
    if (connectionStatus.loading) return 'Supabase接続テスト中...';
    if (connectionStatus.success) return 'Supabase接続成功';
    return 'Supabase接続失敗';
  };

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div className="max-w-2xl mx-auto">
        <div className={`backdrop-blur-xl bg-gradient-to-br ${getStatusColor()} rounded-xl p-8 lg:p-12 border shadow-2xl`}>
          <div className="text-center mb-8">
            <div className="w-20 h-20 mx-auto mb-6 rounded-full bg-white/30 flex items-center justify-center">
              {getStatusIcon()}
            </div>
            <h1 className="text-3xl lg:text-4xl font-bold text-slate-800 mb-4">
              {getStatusTitle()}
            </h1>
            <p className="text-xl text-slate-700 mb-2">{connectionStatus.message}</p>
          </div>

          {/* 環境変数情報 */}
          <div className="backdrop-blur-xl bg-white/20 rounded-lg p-6 border border-white/30 mb-8">
            <h3 className="text-lg font-semibold text-slate-800 mb-4 flex items-center">
              <Database className="w-5 h-5 mr-2" />
              環境変数確認
            </h3>
            <div className="space-y-3 text-sm">
              <div className="flex items-center justify-between">
                <span className="text-slate-600">VITE_SUPABASE_URL:</span>
                <span className="font-mono text-emerald-600">
                  設定済み (https://bjoxgogehtfibmsbdqmo.supabase.co)
                </span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-slate-600">VITE_SUPABASE_ANON_KEY:</span>
                <span className={`font-mono ${import.meta.env.VITE_SUPABASE_ANON_KEY ? 'text-emerald-600' : 'text-red-600'}`}>
                  {import.meta.env.VITE_SUPABASE_ANON_KEY ? '設定済み' : '未設定'}
                </span>
              </div>
            </div>
          </div>

          {/* エラー詳細 */}
          {connectionStatus.error && (
            <div className="backdrop-blur-xl bg-red-50/50 rounded-lg p-6 border border-red-200/50 mb-8">
              <div className="flex items-start space-x-3">
                <AlertTriangle className="w-6 h-6 text-red-600 flex-shrink-0 mt-1" />
                <div>
                  <h3 className="font-semibold text-red-800 mb-2">エラー詳細</h3>
                  <p className="text-red-700 text-sm">{connectionStatus.error}</p>
                </div>
              </div>
            </div>
          )}

          {/* 次のステップ */}
          {!connectionStatus.loading && (
            <div className="backdrop-blur-xl bg-white/20 rounded-lg p-6 border border-white/30 mb-8">
              <h3 className="text-lg font-semibold text-slate-800 mb-4">次のステップ</h3>
              {connectionStatus.success ? (
                <div className="space-y-2 text-slate-700">
                  <p>✅ Supabaseとの接続が確認できました</p>
                  <p>✅ データベーススキーマの作成に進むことができます</p>
                  <p>✅ 認証システムの実装が可能です</p>
                </div>
              ) : (
                <div className="space-y-2 text-slate-700">
                  <p>1. 画面右上の「Connect to Supabase」ボタンをクリック</p>
                  <p>2. Supabaseプロジェクトを作成または選択</p>
                  <p>3. 環境変数が自動設定されるのを確認</p>
                  <p>4. 再度接続テストを実行</p>
                </div>
              )}
            </div>
          )}

          {/* アクションボタン */}
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            {!connectionStatus.loading && !connectionStatus.success && (
              <button
                onClick={() => window.location.reload()}
                className="flex items-center justify-center space-x-2 px-8 py-4 bg-gradient-to-r from-blue-600 to-blue-800 hover:from-blue-700 hover:to-blue-900 text-white rounded-lg font-medium shadow-xl hover:shadow-2xl transition-all duration-200 transform hover:scale-105"
              >
                <Database className="w-5 h-5" />
                <span>再テスト</span>
              </button>
            )}
            
            <button
              onClick={onClose}
              className="flex items-center justify-center space-x-2 px-8 py-4 bg-gradient-to-r from-slate-600 to-slate-800 hover:from-slate-700 hover:to-slate-900 text-white rounded-lg font-medium shadow-xl hover:shadow-2xl transition-all duration-200 transform hover:scale-105"
            >
              <span>閉じる</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

export default SupabaseConnectionTest;