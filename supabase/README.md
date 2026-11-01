# Quest Library content (Supabase)

The Explore tab reads its cards from the `public.quest_library` table. The app
never writes to it, so content can be added or edited from the Supabase
dashboard without releasing a new build.

## Apply the schema and seed

In the Supabase dashboard, open **SQL Editor** and run these files in order:

1. `supabase/migrations/20261101120000_create_quest_library.sql`
2. `supabase/seed.sql`

Or, from a machine with database access:

```bash
psql "$DATABASE_URL" -f supabase/migrations/20261101120000_create_quest_library.sql
psql "$DATABASE_URL" -f supabase/seed.sql
```

Or with the Supabase CLI after `npx supabase@latest login`:

```bash
npx supabase@latest db query --linked --project-ref qyxnhmnfzcxbtphzwsiq \
  --file supabase/migrations/20261101120000_create_quest_library.sql

npx supabase@latest db query --linked --project-ref qyxnhmnfzcxbtphzwsiq \
  --file supabase/seed.sql
```

`seed.sql` is idempotent: re-running it updates the original quests in place.

## Adding a quest

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

## Artwork

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

## Security

Row level security is enabled. `anon` and `authenticated` can only `select`
active rows; inserts, updates and deletes require the service role (dashboard
or server-side tooling).
