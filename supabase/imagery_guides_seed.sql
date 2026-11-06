-- Imagery Guide seed
-- Every guide, filter chip and screen label that used to be hardcoded in
-- ImageryGuide.swift lives here. Safe to run more than once: existing rows are
-- updated in place.

insert into public.imagery_guide_tags (title, icon, sort_order)
values
    ('Cozy',  'sofa',       10),
    ('Peace', 'leaf.fill',  20),
    ('Fresh', 'wind',       30),
    ('Own',   'heart.fill', 40)
on conflict (title) do update set
    icon = excluded.icon,
    sort_order = excluded.sort_order,
    is_active = true;

insert into public.imagery_guides
    (id, title, description, tag, icon, detail_text, image_url,
     image_shift, image_scale, audio_url, steps, completion_text,
     duration_seconds, duration_label, sort_order)
values
    (
        'cozy-room',
        'A Cozy Room',
        'Imagine yourself in a cozy room where you feel safe, comfortable, and relaxed.',
        'Cozy',
        'sofa',
        'Imagine a quiet, warm room. Picture the soft sofa beneath you and the gentle light around you. You can listen to the guidance or simply explore the scene in your own way.',
        'https://qyxnhmnfzcxbtphzwsiq.supabase.co/storage/v1/object/public/imagery-guide/cozy_room.png',
        -66.5,
        1,
        'https://qyxnhmnfzcxbtphzwsiq.supabase.co/storage/v1/object/public/music/cozy_room_ambient.mp3',
        jsonb_build_array(
            'Picture a comfortable room. Notice the soft light on the walls.',
            'Notice the soft sofa and the warm blanket. Let your body settle.',
            'Take one slow breath. When you are ready, come back to the room.'
        ),
        'You took a moment to slow down, breathe, and imagine a place where you feel at peace.',
        120,
        '2 min',
        10
    ),
    (
        'calm-garden',
        'A Calm Garden',
        'Imagine a peaceful garden with gentle sounds, fresh air, and greenery all around you.',
        'Peace',
        'tree',
        'Imagine a peaceful garden, fresh flowers, and a gentle breeze. Take a deep breath and let yourself relax.',
        'https://qyxnhmnfzcxbtphzwsiq.supabase.co/storage/v1/object/public/imagery-guide/calm_garden.png',
        0,
        1,
        'https://qyxnhmnfzcxbtphzwsiq.supabase.co/storage/v1/object/public/music/calm_garden_ambient.mp3',
        jsonb_build_array(
            'Picture a quiet garden. Notice the green around you and the gentle sounds.',
            'Feel the fresh air and the soft breeze. Let your shoulders relax.',
            'Take one slow breath. When you are ready, come back to the garden.'
        ),
        'You took a moment to slow down, breathe, and picture a calm garden where you feel at peace.',
        120,
        '2 min',
        20
    ),
    (
        'misty-hill',
        'A Misty Hill Station',
        'Imagine cool mountain air, misty green hills, and peaceful morning around you.',
        'Fresh',
        'mountain.2',
        'We’re about to take you to a peaceful, misty hill station. Picture yourself surrounded by cool air, green hills, and soft clouds drifting by. Get ready to unwind.',
        'https://qyxnhmnfzcxbtphzwsiq.supabase.co/storage/v1/object/public/imagery-guide/misty_hill.png',
        0,
        1,
        'https://qyxnhmnfzcxbtphzwsiq.supabase.co/storage/v1/object/public/music/misty_hill_station_ambient.mp3',
        jsonb_build_array(
            'Picture cool mountain air and soft mist over green hills.',
            'Watch the clouds drift slowly by. Let each breath feel cool and light.',
            'Take one slow breath. When you are ready, come back to the hills.'
        ),
        'You took a moment to slow down, breathe, and picture a misty hill station where you feel at peace.',
        120,
        '2 min',
        30
    ),
    (
        'childhood-memory',
        'A Childhood Memory',
        'Imagine a happy childhood moment that makes you feel safe, warm, and at peace.',
        'Own',
        'teddybear',
        'Imagine a happy childhood memory, filled with familiar faces, warm smiles, and simple joys. Take a deep breath and let yourself feel safe, calm, and relaxed.',
        'https://qyxnhmnfzcxbtphzwsiq.supabase.co/storage/v1/object/public/imagery-guide/childhood_memory.png',
        0,
        1.061,
        'https://qyxnhmnfzcxbtphzwsiq.supabase.co/storage/v1/object/public/music/childhood_memory_ambient.mp3',
        jsonb_build_array(
            'Picture a happy childhood moment. Notice who is with you and how it feels.',
            'Notice the warm evening light and the comfort of being together.',
            'Take one slow breath. When you are ready, come back to the present.'
        ),
        'You took a moment to slow down, breathe, and revisit a childhood memory that makes you feel safe and at peace.',
        120,
        '2 min',
        40
    )
on conflict (id) do update set
    title = excluded.title,
    description = excluded.description,
    tag = excluded.tag,
    icon = excluded.icon,
    detail_text = excluded.detail_text,
    image_url = excluded.image_url,
    image_shift = excluded.image_shift,
    image_scale = excluded.image_scale,
    audio_url = excluded.audio_url,
    steps = excluded.steps,
    completion_text = excluded.completion_text,
    duration_seconds = excluded.duration_seconds,
    duration_label = excluded.duration_label,
    sort_order = excluded.sort_order,
    is_active = true;

-- Shared copy for every Imagery Guide screen.
insert into public.imagery_guide_screen_content
    (id, eyebrow, title, guides_count_format, all_filter_title, all_filter_icon,
     error_icon, empty_icon, card_open_icon, duration_icon,
     list_accessibility_hint, accessibility_label_format,
     loading_text, error_title, error_message, retry_button_title,
     empty_title, empty_message,
     session_step_format, session_paused_suffix, session_complete_header,
     session_complete_instruction_format, session_elapsed_format,
     session_remaining_format, session_restart_label, session_pause_label,
     session_play_label, session_restart_icon, session_pause_icon,
     session_play_icon, session_continue_button,
     complete_title, complete_subtitle, complete_headline, complete_done_button,
     complete_default_message, session_complete_navigation_title)
values
    (
        1,
        'GUIDED IMAGERY',
        'Imagery Guide',
        '{count} GUIDES',
        'All',
        'square.grid.2x2.fill',
        'wifi.exclamationmark',
        'sparkles',
        'arrow.up.right',
        'clock',
        'Opens the guide',
        '{title}, {tag}, {duration} guided imagery',
        'Loading guides…',
        'Couldn''t load guides',
        'Check your connection and try again.',
        'Try Again',
        'No guides yet',
        'New guides will appear here as soon as they''re added.',
        'STEP {current} OF {total}',
        ' · PAUSED',
        'SESSION COMPLETE',
        'You imagined for {duration}. Take a moment before you continue.',
        'Elapsed {duration}',
        'Remaining {duration}',
        'Restart',
        'Pause',
        'Play',
        'arrow.counterclockwise',
        'pause.fill',
        'play.fill',
        'Continue',
        'Imagery Guide',
        'Breathing and guided imagery paired together',
        'You did it!',
        'Done',
        'You took a moment to slow down, breathe, and imagine a place where you feel at peace.',
        'Session complete'
    )
on conflict (id) do update set
    eyebrow = excluded.eyebrow,
    title = excluded.title,
    guides_count_format = excluded.guides_count_format,
    all_filter_title = excluded.all_filter_title,
    all_filter_icon = excluded.all_filter_icon,
    error_icon = excluded.error_icon,
    empty_icon = excluded.empty_icon,
    card_open_icon = excluded.card_open_icon,
    duration_icon = excluded.duration_icon,
    list_accessibility_hint = excluded.list_accessibility_hint,
    accessibility_label_format = excluded.accessibility_label_format,
    loading_text = excluded.loading_text,
    error_title = excluded.error_title,
    error_message = excluded.error_message,
    retry_button_title = excluded.retry_button_title,
    empty_title = excluded.empty_title,
    empty_message = excluded.empty_message,
    session_step_format = excluded.session_step_format,
    session_paused_suffix = excluded.session_paused_suffix,
    session_complete_header = excluded.session_complete_header,
    session_complete_instruction_format = excluded.session_complete_instruction_format,
    session_elapsed_format = excluded.session_elapsed_format,
    session_remaining_format = excluded.session_remaining_format,
    session_restart_label = excluded.session_restart_label,
    session_pause_label = excluded.session_pause_label,
    session_play_label = excluded.session_play_label,
    session_restart_icon = excluded.session_restart_icon,
    session_pause_icon = excluded.session_pause_icon,
    session_play_icon = excluded.session_play_icon,
    session_continue_button = excluded.session_continue_button,
    complete_title = excluded.complete_title,
    complete_subtitle = excluded.complete_subtitle,
    complete_headline = excluded.complete_headline,
    complete_done_button = excluded.complete_done_button,
    complete_default_message = excluded.complete_default_message,
    session_complete_navigation_title = excluded.session_complete_navigation_title;

-- Link artwork that has already been uploaded to the imagery-guide bucket.
-- File names use the guide id with underscores, for example cozy_room.png.
update public.imagery_guides g
set image_url = 'https://qyxnhmnfzcxbtphzwsiq.supabase.co/storage/v1/object/public/imagery-guide/' || o.name
from storage.objects o
where o.bucket_id = 'imagery-guide'
  and replace(g.id, '-', '_') = split_part(o.name, '.', 1);
