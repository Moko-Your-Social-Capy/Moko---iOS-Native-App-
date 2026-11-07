-- Remove the info-screen-only copy columns from imagery_guide_screen_content.
-- The guide detail screen was removed: tapping a guide now opens the session
-- directly, so `detail_start_button` and `detail_caption` are no longer used.
alter table public.imagery_guide_screen_content
    drop column if exists detail_start_button,
    drop column if exists detail_caption;

-- Make PostgREST pick up the changed schema immediately.
notify pgrst, 'reload schema';
