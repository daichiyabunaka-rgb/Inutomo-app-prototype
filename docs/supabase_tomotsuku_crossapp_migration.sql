-- ============================================================
-- 「ともつく！連携」マイグレーション（アプリ横断プロフィール公開）
-- 対象: supabase_multiapp_migration.sql 適用済みの共有Supabaseプロジェクト
--       （追加のみ・非破壊・トランザクション）
--
-- 内容:
--   1. profiles に cross_app_visible 列を追加
--      （true = このプロフィール行を他のともつく！アプリの
--        「近くの人」「探す」にも表示してよい。デフォルト false）
--      アプリ側の「ともつく！連携」設定画面からユーザーが切り替える。
--
-- 前提: docs/supabase_multiapp_migration.sql （app_id 分離・profiles 複数行化）
--       が適用済みであること。
--
-- 注意: この列が無い状態で cross_app_visible に対応した新版APKを起動すると、
--       「近くの人」取得（cross_app_visible.eq.true のフィルタ）が
--       エラーになるため、APKリリース前に必ず実行すること。
-- ============================================================

begin;

-- ------------------------------------------------------------
-- 1. アプリ横断公開フラグ
-- ------------------------------------------------------------
alter table public.profiles
  add column if not exists cross_app_visible boolean not null default false;

commit;
