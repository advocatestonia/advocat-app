-- ============================================================================
-- 20260523050000_org_branding.sql
-- Migration 35/37 — White-label storage bucket + brand-resolve public RPC.
--
-- Bucket layout:  org-branding/<org_uuid>/logo.<ext>
-- Visibility:     public-read (URLs are unguessable + signed by Supabase)
-- Upload/delete:  admin/owner only via storage.objects RLS
-- Brand resolve:  public RPC by org slug; only paid plans return rows.
-- ============================================================================

-- ── bucket (idempotent insert) ───────────────────────────────────────────────
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'org-branding',
  'org-branding',
  true,
  5242880,                                              -- 5 MB
  array['image/png','image/jpeg','image/svg+xml','image/webp']
) on conflict (id) do update
  set public             = excluded.public,
      file_size_limit    = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- ── storage RLS: upload/delete restricted to admins of the path's org ────────
-- Path convention: org-branding/<org_uuid>/<filename>
-- storage.foldername(name) returns text[]; element 1 is the org UUID.

drop policy if exists org_branding_upload_admin on storage.objects;
create policy org_branding_upload_admin
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'org-branding'
    and (storage.foldername(name))[1]::uuid in (select public.current_user_org_ids())
    and public.current_user_org_role(((storage.foldername(name))[1])::uuid) in ('owner','admin')
  );

drop policy if exists org_branding_update_admin on storage.objects;
create policy org_branding_update_admin
  on storage.objects for update to authenticated
  using (
    bucket_id = 'org-branding'
    and (storage.foldername(name))[1]::uuid in (select public.current_user_org_ids())
    and public.current_user_org_role(((storage.foldername(name))[1])::uuid) in ('owner','admin')
  )
  with check (
    bucket_id = 'org-branding'
    and (storage.foldername(name))[1]::uuid in (select public.current_user_org_ids())
    and public.current_user_org_role(((storage.foldername(name))[1])::uuid) in ('owner','admin')
  );

drop policy if exists org_branding_delete_admin on storage.objects;
create policy org_branding_delete_admin
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'org-branding'
    and (storage.foldername(name))[1]::uuid in (select public.current_user_org_ids())
    and public.current_user_org_role(((storage.foldername(name))[1])::uuid) in ('owner','admin')
  );

-- ── public brand-resolve RPC ─────────────────────────────────────────────────
-- Returns 0 rows for non-existent slugs or starter-tier orgs.
create or replace function public.resolve_org_brand_by_slug(p_slug text)
returns table (
  org_id        uuid,
  logo_url      text,
  primary_color text,
  accent_color  text,
  custom_domain text,
  support_email text,
  footer_html   text
)
language sql
stable
security definer
set search_path = public
as $$
  select o.id,
         b.logo_url,
         b.primary_color,
         b.accent_color,
         b.custom_domain,
         b.support_email,
         b.footer_html
  from public.organizations o
  left join public.org_branding b on b.org_id = o.id
  where o.slug = p_slug
    and o.deleted_at is null
    and o.plan in ('firm','enterprise')
  limit 1
$$;

grant execute on function public.resolve_org_brand_by_slug(text) to anon, authenticated;

notify pgrst, 'reload schema';

-- ROLLBACK:
-- drop function if exists public.resolve_org_brand_by_slug(text);
-- drop policy if exists org_branding_upload_admin on storage.objects;
-- drop policy if exists org_branding_update_admin on storage.objects;
-- drop policy if exists org_branding_delete_admin on storage.objects;
-- delete from storage.buckets where id = 'org-branding';
