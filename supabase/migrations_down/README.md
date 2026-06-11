# Down-migrations (rollback scripts)

These `*.down.sql` files are MANUAL rollback companions to forward migrations of the
same version in `../migrations/`. They were moved out of `supabase/migrations/`
on 2026-06-11 because the Supabase CLI (v2.84.2) parses every `.sql` file in that
directory as a forward migration: each `.down.sql` shared a version number with its
forward file, producing duplicate-version rows in `supabase migration list` and
desyncing `supabase db push`.

Never put these back into `supabase/migrations/`. To roll back, run the relevant
file manually (SQL editor / `psql`) and then
`supabase migration repair --status reverted <version> --linked`.
