-- 犬とも！ベータ版マイグレーション: 保護犬・迷子犬の投稿写真バケット
-- docs/supabase_schema.sql の protected_dogs テーブルと合わせて使う。
-- 公開バケット protected-dog-photos を作り、ユーザーごとの UUID 名前空間へ配置する。

insert into storage.buckets (id, name, public)
values ('protected-dog-photos', 'protected-dog-photos', true)
on conflict (id) do nothing;

-- ポリシーの重複対策
drop policy if exists "保護犬写真は公開読み取り可" on storage.objects;
drop policy if exists "認証ユーザーは自分の保護犬写真をアップロード可" on storage.objects;
drop policy if exists "認証ユーザーは自分の保護犬写真を削除可" on storage.objects;

-- 公開バケットなので誰でも閲覧可（一覧表示に必要）
create policy "保護犬写真は公開読み取り可" on storage.objects
  for select using (bucket_id = 'protected-dog-photos');

-- アップロードは認証ユーザー本人の名前空間（<uuid>/...）のみ
create policy "認証ユーザーは自分の保護犬写真をアップロード可" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'protected-dog-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "認証ユーザーは自分の保護犬写真を削除可" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'protected-dog-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
