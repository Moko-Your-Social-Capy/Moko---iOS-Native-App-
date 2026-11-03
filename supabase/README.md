# Moko content (Supabase)

Read-only content for the app lives in Supabase: the Explore tab's Quest Library
and the Relax tab's Imagery Guides. The app never writes to these tables, so copy,
instructions and artwork can be edited from the Supabase dashboard without
releasing a new build.

## Apply the schema and seed

In the Supabase dashboard, open **SQL Editor** and run these files in order:

1. `supabase/migrations/20261101120000_create_quest_library.sql`
2. `supabase/migrations/20261101130000_add_quest_image_url_and_storage.sql`
3. `supabase/migrations/20261103120000_create_imagery_guides.sql`
4. `supabase/seed.sql`
5. `supabase/imagery_guides_seed.sql`

Or, from a machine with database access:

```bash
psql "$DATABASE_URL" -f supabase/migrations/20261101120000_create_quest_library.sql
psql "$DATABASE_URL" -f supabase/migrations/20261101130000_add_quest_image_url_and_storage.sql
psql "$DATABASE_URL" -f supabase/migrations/20261103120000_create_imagery_guides.sql
psql "$DATABASE_URL" -f supabase/seed.sql
psql "$DATABASE_URL" -f supabase/imagery_guides_seed.sql
```

Or with the Supabase CLI after `npx supabase@latest login`:

```bash
npx supabase@latest db query --remote=qyxnhmnfzcxbtphzwsiq \
  --file supabase/migrations/20261101120000_create_quest_library.sql

npx supabase@latest db query --remote=qyxnhmnfzcxbtphzwsiq \
  --file supabase/migrations/20261101130000_add_quest_image_url_and_storage.sql

npx supabase@latest db query --remote=qyxnhmnfzcxbtphzwsiq \
  --file supabase/migrations/20261103120000_create_imagery_guides.sql

npx supabase@latest db query --remote=qyxnhmnfzcxbtphzwsiq \
  --file supabase/seed.sql

npx supabase@latest db query --remote=qyxnhmnfzcxbtphzwsiq \
  --file supabase/imagery_guides_seed.sql
```

Both seed files are idempotent: re-running them updates the original rows in
place.

## Quest Library

The Explore tab reads its cards from the `public.quest_library` table.

### Adding a quest

Insert one row into `quest_library`:

```sql
insert into public.quest_library
    (category, category_sort_order, title, image_name, xp, tint_hex, sort_order)
values
    ('Work', 10, 'Ask for feedback', 'quest_ask_for_feedback', 150, '#F5E6D3', 60);
```

- `category` is the section heading in the app.
- `category_sort_order` controls where the section appears (10, 20, 30...).
- `sort_order` controls the card order inside the section.
- `image_name` is the stable artwork slug (for example `quest_speak_up`).
- `image_url` is the public URL from the `quest-library` Storage bucket.
- `tint_hex` is the card artwork background (`#RRGGBB`).
- `is_active` defaults to `true`. Set it to `false` to hide a quest.

Adding a row with a new `category` automatically creates a new section in the
app. If the category is not one of the app's known categories (`Work`,
`Dating`, `Friends`, `Family`, `Others`), the quest is saved under `Others`
when the user adds it to their Quests.

### Quest artwork

Quest images live in the public `quest-library` Storage bucket, not in the app
bundle. Upload a file, copy its public URL, and set it on the row:

```sql
update public.quest_library
set image_url = 'https://qyxnhmnfzcxbtphzwsiq.supabase.co/storage/v1/object/public/quest-library/quest_speak_up.png'
where category = 'Work' and title = 'Speak up in a meeting';
```

If every file is named after its `image_name` with a `.png` extension, this
updates all rows at once:

```sql
update public.quest_library
set image_url = 'https://qyxnhmnfzcxbtphzwsiq.supabase.co/storage/v1/object/public/quest-library/'
                || image_name || '.png'
where image_name is not null;
```

The app uses `image_url` first, then `image_name` if that artwork is bundled,
then the category symbol. Missing or broken URLs therefore never leave an
empty card. Re-running `seed.sql` also links any artwork already uploaded to
the bucket automatically.

## Imagery Guides

The Relax > Imagery flow is fully content-driven. These tables hold everything
the screens render:

| Table | What it controls |
| --- | --- |
| `public.imagery_guides` | Guide cards, detail text, timer instructions, completion message, artwork URL, duration and framing |
| `public.imagery_guide_tags` | Filter chips above the list, including their SF Symbols |
| `public.imagery_guide_screen_content` | Shared screen copy: headings, buttons, loading/error/empty states and label templates |

### Editing a guide

Update a row in place:

```sql
update public.imagery_guides
set title = 'A Very Cozy Room',
    description = 'A softer, warmer place to settle.',
    steps = jsonb_build_array(
        'Picture a comfortable room. Notice the soft light on the walls.',
        'Notice the soft sofa and the warm blanket. Let your body settle.',
        'Take one slow breath. When you are ready, come back to the room.'
    )
where id = 'cozy-room';
```

- `tag` must match a `title` in `imagery_guide_tags`.
- `icon` and the tag `icon` are SF Symbol names.
- `steps` is a JSON array of strings, shown in order while the timer runs.
- `duration_seconds` controls the timer; `duration_label` is the short text on
  the card (for example `2 min`).
- `image_shift` and `image_scale` tune how the full-screen photo is framed.
- `is_active` defaults to `true`. Set it to `false` to hide a guide.

Add a new guide by inserting a row with a new stable `id`. New filter tags are
created by inserting into `imagery_guide_tags` first.

### Shared screen copy

`imagery_guide_screen_content` always has exactly one row (`id = 1`). Edit its
columns to change labels without touching the app:

- `guides_count_format` uses `{count}`, for example `{count} GUIDES`.
- `session_step_format` uses `{current}` and `{total}`.
- `session_complete_instruction_format` uses `{duration}`.
- `session_elapsed_format` and `session_remaining_format` use `{duration}`.
- `accessibility_label_format` uses `{title}`, `{tag}` and `{duration}`.

### Imagery artwork

The four guide photos live in the public `imagery-guide` Storage bucket. Source
files are kept in `supabase/imagery-guide/` so they can be uploaded without
being bundled into the app:

| File | Guide id |
| --- | --- |
| `cozy_room.png` | `cozy-room` |
| `calm_garden.png` | `calm-garden` |
| `misty_hill.png` | `misty-hill` |
| `childhood_memory.png` | `childhood-memory` |

Upload them from **Storage > imagery-guide** in the dashboard, or with the CLI:

```bash
for file in supabase/imagery-guide/*.png; do
  npx supabase@latest storage cp "$file" \
    "ss:///imagery-guide/$(basename "$file")" --remote=qyxnhmnfzcxbtphzwsiq \
    --experimental
done
```

Re-running `imagery_guides_seed.sql` links every uploaded file to its guide
automatically when the file name matches the guide id with underscores
(`cozy-room` -> `cozy_room.png`). Broken or missing artwork falls back to the
guide's SF Symbol, so no card is left blank.

## Security

Row level security is enabled. `anon` and `authenticated` can only `select`
active rows and shared screen copy; inserts, updates and deletes require the
service role (dashboard or server-side tooling).
