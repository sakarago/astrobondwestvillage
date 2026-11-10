-- Profile photos: run once in the Supabase SQL editor.
-- Public bucket => objects are served through the Supabase CDN (cached at the edge).
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('profile-photos', 'profile-photos', true, 2097152, array['image/jpeg'])
on conflict (id) do update set public = true, file_size_limit = 2097152, allowed_mime_types = array['image/jpeg'];

-- Anyone can read (public bucket); each user can only write inside their own folder "<uid>/...".
drop policy if exists "profile photos: owner insert" on storage.objects;
create policy "profile photos: owner insert" on storage.objects for insert to authenticated
  with check (bucket_id = 'profile-photos' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "profile photos: owner update" on storage.objects;
create policy "profile photos: owner update" on storage.objects for update to authenticated
  using (bucket_id = 'profile-photos' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "profile photos: owner delete" on storage.objects;
create policy "profile photos: owner delete" on storage.objects for delete to authenticated
  using (bucket_id = 'profile-photos' and (storage.foldername(name))[1] = auth.uid()::text);
