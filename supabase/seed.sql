-- Quest Library seed
-- Every quest that used to be hardcoded in QuestLibraryView.swift lives here.
-- Safe to run more than once: existing (category, title) rows are updated in place.

insert into public.quest_library
    (category, category_sort_order, title, image_name, xp, tint_hex, sort_order)
values
    -- Work
    ('Work',   10, 'Speak up in a meeting',     'quest_speak_up',              100, '#FAEDD9', 10),
    ('Work',   10, 'Decline extra work',        'quest_decline_extra_work',    150, '#F5E6D3', 20),
    ('Work',   10, 'Correct your boss',         'quest_correct_your_boss',     200, '#F0DFC8', 30),
    ('Work',   10, 'Ask for a Raise',           'quest_ask_for_a_raise',       250, '#EBD8BC', 40),
    ('Work',   10, 'Ask a Mentor',              'quest_ask_a_mentor',          300, '#E6D1B1', 50),

    -- Dating
    ('Dating', 20, 'Send the first message',    'quest_send_first_message',    100, '#FBE7E4', 10),
    ('Dating', 20, 'Name what you felt',        'quest_name_what_you_felt',    150, '#F8DAD4', 20),
    ('Dating', 20, 'Ask where things stand',    'quest_ask_where_things_stand',200, '#F5CBBE', 30),
    ('Dating', 20, 'First Date',                'quest_first_date',            250, '#F1BDAE', 40),
    ('Dating', 20, 'The Ex',                    'quest_the_ex',                300, '#EDAF9F', 50),

    -- Friends
    ('Friends', 30, 'Say you’re hurt',          'quest_say_youre_hurt',        100, '#E7EFE9', 10),
    ('Friends', 30, 'Bring up the distance',    'quest_bring_up_distance',     150, '#DBE8DE', 20),
    ('Friends', 30, 'Turn down the plan',       'quest_turn_down_plan',        200, '#CEDECF', 30),
    ('Friends', 30, 'Make a Real Friend',       'quest_make_a_real_friend',    250, '#C1D4C3', 40),
    ('Friends', 30, 'Check On a Friend',        'quest_check_on_a_friend',     300, '#B4CAB7', 50),

    -- Family
    ('Family', 40, 'The Holiday Table',         'quest_holiday_table',         100, '#E9EBF7', 10),
    ('Family', 40, 'The Sibling Talk',          'quest_sibling_talk',          150, '#DDE1F2', 20),
    ('Family', 40, 'Hold the Line with Mom',    'quest_hold_the_line_with_mom',200, '#CED4EC', 30),
    ('Family', 40, 'Open Up to Dad',            'quest_open_up_to_dad',        250, '#C0C8E6', 40),
    ('Family', 40, 'Handle the Relatives',      'quest_handle_the_relatives',  300, '#B3BCE0', 50)
on conflict (category, title) do update set
    category_sort_order = excluded.category_sort_order,
    image_name = excluded.image_name,
    xp = excluded.xp,
    tint_hex = excluded.tint_hex,
    sort_order = excluded.sort_order,
    is_active = true;

-- Link artwork that has already been uploaded to the quest-library bucket.
-- Keeps image_url current without forcing a full re-seed of the rows.
update public.quest_library q
set image_url = 'https://qyxnhmnfzcxbtphzwsiq.supabase.co/storage/v1/object/public/quest-library/' || o.name
from storage.objects o
where o.bucket_id = 'quest-library'
  and split_part(o.name, '.', 1) = q.image_name
  and q.image_name is not null;
