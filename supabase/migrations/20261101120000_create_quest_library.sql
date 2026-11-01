-- Quest Library
-- Content for the Explore > Quest Library screen. The iOS app only reads from
-- this table; new quests and categories are added from the Supabase dashboard
-- or with SQL, without shipping an app update.

create table if not exists public.quest_library (
    id uuid primary key default gen_random_uuid(),
    -- Display name of the section, e.g. 'Work', 'Dating', 'Friends', 'Family'.
    category text not null,
    -- Controls section order in the app. Use gaps (10, 20, 30...) so new
    -- categories can be inserted without renumbering existing rows.
    category_sort_order integer not null default 0,
    title text not null,
    -- Name of the image in Assets.xcassets. Nullable: the card falls back to
    -- the category's SF Symbol when the artwork is not available yet.
    image_name text,
    xp integer not null check (xp > 0),
    -- Card artwork tint, stored as '#RRGGBB'.
    tint_hex text not null default '#FAEDD9',
    -- Controls card order inside its category.
    sort_order integer not null default 0,
    -- Set to false to hide a quest without deleting it.
    is_active boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint quest_library_category_title_key unique (category, title)
);

comment on table public.quest_library is
    'Read-only quest content shown in the Moko Quest Library, grouped by category.';
comment on column public.quest_library.category is
    'Section name shown in the app. New values automatically create a new section.';
comment on column public.quest_library.category_sort_order is
    'Ascending order of category sections in the app.';
comment on column public.quest_library.sort_order is
    'Ascending order of cards inside a category.';
comment on column public.quest_library.is_active is
    'Only active rows are returned to the app.';

create index if not exists quest_library_order_idx
    on public.quest_library (category_sort_order, category, sort_order);

-- Keep updated_at accurate when content is edited.
create or replace function public.set_quest_library_updated_at()
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

drop trigger if exists quest_library_set_updated_at on public.quest_library;
create trigger quest_library_set_updated_at
    before update on public.quest_library
    for each row
    execute function public.set_quest_library_updated_at();

-- Row level security: anyone using the app can read active content, but only
-- the service role (dashboard / server) can write it.
alter table public.quest_library enable row level security;

drop policy if exists "Quest library is publicly readable" on public.quest_library;
create policy "Quest library is publicly readable"
    on public.quest_library
    for select
    to anon, authenticated
    using (is_active = true);

revoke all on table public.quest_library from anon, authenticated;
grant select on table public.quest_library to anon, authenticated;

-- Make PostgREST pick up the new table immediately.
notify pgrst, 'reload schema';
