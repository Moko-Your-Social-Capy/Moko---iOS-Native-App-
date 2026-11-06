-- Add ambient background music URL to each imagery guide.
-- The sound lives in the imagery-guide Supabase Storage bucket and loops
-- softly while the session is running; pause/play controls both together.
alter table public.imagery_guides
    add column if not exists audio_url text;

comment on column public.imagery_guides.audio_url is
    'Public Supabase Storage URL of the ambient background music for the session.';

notify pgrst, 'reload schema';
