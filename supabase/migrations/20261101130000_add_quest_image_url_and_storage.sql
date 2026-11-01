-- Quest Library artwork
-- Images live in a public Supabase Storage bucket instead of the app bundle.
-- The app reads `image_url`; `image_name` stays as the stable file slug used
-- when uploading artwork.

alter table public.quest_library
    add column if not exists image_url text;

comment on column public.quest_library.image_url is
    'Public Supabase Storage URL for the quest card artwork. Null falls back to the category symbol.';

-- Public bucket for quest card artwork. Anyone can read; only the service role
-- (dashboard / server-side tooling) can upload, replace or delete files.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
    'quest-library',
    'quest-library',
    true,
    5242880,
    array['image/png', 'image/jpeg', 'image/webp', 'image/heic', 'image/avif']
)
on conflict (id) do update set
    public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Quest library images are publicly readable" on storage.objects;
create policy "Quest library images are publicly readable"
    on storage.objects
    for select
    to anon, authenticated
    using (bucket_id = 'quest-library');

notify pgrst, 'reload schema';
