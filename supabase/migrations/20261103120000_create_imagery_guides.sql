-- Imagery Guides
-- Content for Relax > Imagery. The iOS app only reads from these tables, so
-- guides, filter chips, instructions and labels can be edited from the
-- Supabase dashboard without shipping an app update.

-- Filter chips shown above the guide list (All uses the screen copy below).
create table if not exists public.imagery_guide_tags (
    title text primary key,
    icon text not null,
    sort_order integer not null default 0,
    is_active boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

comment on table public.imagery_guide_tags is
    'Filter chips for the Relax > Imagery guide list.';
comment on column public.imagery_guide_tags.icon is
    'SF Symbol name shown next to the chip title.';

-- One row per imagery guide card.
create table if not exists public.imagery_guides (
    -- Stable slug used by the app and by the Storage file name.
    id text primary key,
    title text not null,
    description text not null,
    tag text not null references public.imagery_guide_tags (title) on update cascade,
    icon text not null,
    detail_text text not null,
    -- Public URL in the imagery-guide Storage bucket.
    image_url text,
    -- Framing applied to the full-screen session artwork.
    image_shift double precision not null default 0,
    image_scale double precision not null default 1,
    -- Instructions shown while the timer runs, in order.
    steps jsonb not null default '[]'::jsonb,
    completion_text text not null,
    duration_seconds integer not null default 120 check (duration_seconds > 0),
    duration_label text not null default '2 min',
    sort_order integer not null default 0,
    is_active boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

comment on table public.imagery_guides is
    'Read-only guided imagery content shown in the Moko Relax tab.';
comment on column public.imagery_guides.icon is
    'SF Symbol name shown on the guide card and detail screen.';
comment on column public.imagery_guides.image_url is
    'Public Supabase Storage URL. Null falls back to the guide icon.';
comment on column public.imagery_guides.duration_seconds is
    'Timer length for the session screen.';
comment on column public.imagery_guides.duration_label is
    'Short duration shown on the card, for example 2 min.';

-- All copy used by the list, detail, session and completion screens.
-- Exactly one row is kept; the app reads id = 1.
create table if not exists public.imagery_guide_screen_content (
    id integer primary key default 1 check (id = 1),
    eyebrow text not null,
    title text not null,
    guides_count_format text not null,
    all_filter_title text not null,
    all_filter_icon text not null,
    error_icon text not null,
    empty_icon text not null,
    card_open_icon text not null,
    duration_icon text not null,
    list_accessibility_hint text not null,
    accessibility_label_format text not null,
    loading_text text not null,
    error_title text not null,
    error_message text not null,
    retry_button_title text not null,
    empty_title text not null,
    empty_message text not null,
    detail_start_button text not null,
    detail_caption text not null,
    session_step_format text not null,
    session_paused_suffix text not null,
    session_complete_header text not null,
    session_complete_instruction_format text not null,
    session_elapsed_format text not null,
    session_remaining_format text not null,
    session_restart_label text not null,
    session_pause_label text not null,
    session_play_label text not null,
    session_restart_icon text not null,
    session_pause_icon text not null,
    session_play_icon text not null,
    session_continue_button text not null,
    complete_title text not null,
    complete_subtitle text not null,
    complete_headline text not null,
    complete_done_button text not null,
    complete_default_message text not null,
    session_complete_navigation_title text not null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

comment on table public.imagery_guide_screen_content is
    'Shared labels and screen copy for Relax > Imagery.';
comment on column public.imagery_guide_screen_content.guides_count_format is
    'Toolbar count template. {count} is replaced with the number of guides.';

-- Keep updated_at accurate when content is edited.
create or replace function public.set_imagery_guide_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists imagery_guide_tags_set_updated_at on public.imagery_guide_tags;
create trigger imagery_guide_tags_set_updated_at
    before update on public.imagery_guide_tags
    for each row
    execute function public.set_imagery_guide_updated_at();

drop trigger if exists imagery_guides_set_updated_at on public.imagery_guides;
create trigger imagery_guides_set_updated_at
    before update on public.imagery_guides
    for each row
    execute function public.set_imagery_guide_updated_at();

drop trigger if exists imagery_guide_screen_content_set_updated_at on public.imagery_guide_screen_content;
create trigger imagery_guide_screen_content_set_updated_at
    before update on public.imagery_guide_screen_content
    for each row
    execute function public.set_imagery_guide_updated_at();

create index if not exists imagery_guides_order_idx
    on public.imagery_guides (sort_order);

-- Public bucket for the full-screen guide artwork.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
    'imagery-guide',
    'imagery-guide',
    true,
    5242880,
    array['image/png', 'image/jpeg', 'image/webp', 'image/heic', 'image/avif']
)
on conflict (id) do update set
    public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Imagery guide images are publicly readable" on storage.objects;
create policy "Imagery guide images are publicly readable"
    on storage.objects
    for select
    to anon, authenticated
    using (bucket_id = 'imagery-guide');

-- Row level security: anyone using the app can read active content, but only
-- the service role (dashboard / server-side tooling) can write it.
alter table public.imagery_guide_tags enable row level security;

drop policy if exists "Imagery guide tags are publicly readable" on public.imagery_guide_tags;
create policy "Imagery guide tags are publicly readable"
    on public.imagery_guide_tags
    for select
    to anon, authenticated
    using (is_active = true);

alter table public.imagery_guides enable row level security;

drop policy if exists "Imagery guides are publicly readable" on public.imagery_guides;
create policy "Imagery guides are publicly readable"
    on public.imagery_guides
    for select
    to anon, authenticated
    using (is_active = true);

alter table public.imagery_guide_screen_content enable row level security;

drop policy if exists "Imagery guide screen content is publicly readable" on public.imagery_guide_screen_content;
create policy "Imagery guide screen content is publicly readable"
    on public.imagery_guide_screen_content
    for select
    to anon, authenticated
    using (true);

revoke all on table public.imagery_guide_tags from anon, authenticated;
revoke all on table public.imagery_guides from anon, authenticated;
revoke all on table public.imagery_guide_screen_content from anon, authenticated;

grant select on table public.imagery_guide_tags to anon, authenticated;
grant select on table public.imagery_guides to anon, authenticated;
grant select on table public.imagery_guide_screen_content to anon, authenticated;

-- Make PostgREST pick up the new tables immediately.
notify pgrst, 'reload schema';
