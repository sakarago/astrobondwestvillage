-- Multi-photo profile gallery: run once in the Supabase SQL editor
-- (after Notes/ProfilePhotosSupabase.sql, which creates the bucket + storage policies).

create table if not exists public.profile_photos (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  path        text not null,          -- storage path inside bucket "profile-photos"
  url         text not null,          -- public URL (full size); thumbnail = same name + "-thumb.jpg"
  position    int  not null default 0,
  created_at  timestamptz not null default now()
);

create index if not exists profile_photos_user_pos_idx on public.profile_photos (user_id, position);

alter table public.profile_photos enable row level security;

-- Signed-in users can read photos (the app decides when to show other people's photos).
drop policy if exists "profile_photos: read" on public.profile_photos;
create policy "profile_photos: read" on public.profile_photos
  for select to authenticated using (true);

-- Owners manage their own rows.
drop policy if exists "profile_photos: owner insert" on public.profile_photos;
create policy "profile_photos: owner insert" on public.profile_photos
  for insert to authenticated with check (user_id = auth.uid());

drop policy if exists "profile_photos: owner update" on public.profile_photos;
create policy "profile_photos: owner update" on public.profile_photos
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "profile_photos: owner delete" on public.profile_photos;
create policy "profile_photos: owner delete" on public.profile_photos
  for delete to authenticated using (user_id = auth.uid());

-- Max 6 photos per user (enforced server-side too).
create or replace function public.profile_photos_limit() returns trigger language plpgsql as $$
begin
  if (select count(*) from public.profile_photos where user_id = new.user_id) >= 6 then
    raise exception 'photo limit reached';
  end if;
  return new;
end $$;

drop trigger if exists profile_photos_limit_trg on public.profile_photos;
create trigger profile_photos_limit_trg before insert on public.profile_photos
  for each row execute function public.profile_photos_limit();
