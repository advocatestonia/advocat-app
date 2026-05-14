-- contract-reviews bucket RLS — owner-only access.
--
-- Background:
--   The `contract-reviews` storage bucket holds private legal documents
--   (user-uploaded contracts + generated PDF reviews). The bucket was created
--   private with a 50MB cap, but had ZERO row-level security policies. With
--   no policies on storage.objects scoped to this bucket, an authenticated
--   user calling the storage REST API directly would be denied (default
--   deny on RLS-enabled tables), but the absence of policies makes the
--   posture fragile: any future bucket-wide grant or misconfigured edge
--   function could leak files across tenants.
--
-- Fix:
--   Add explicit owner-only SELECT / INSERT / DELETE policies keyed on the
--   first folder of the object path being the user's auth.uid. Path
--   convention is `{user_id}/{timestamp}_{filename}.pdf` (see
--   buildStoragePath() in supabase/functions/contract-review/handler.ts).
--
-- Preserved access paths:
--   - Edge functions using SUPABASE_SERVICE_ROLE_KEY bypass RLS (uploads work).
--   - Signed URLs minted by the service role bypass RLS (chat UI viewer works).
--
-- Blocked access paths:
--   - Direct REST reads of another user's path without a signed URL → 403.
--   - Cross-tenant writes from a misconfigured edge fn using a user JWT → 403.

-- Owner-only SELECT
create policy "contract_reviews_owner_select"
on storage.objects for select
to authenticated
using (
  bucket_id = 'contract-reviews'
  and auth.uid()::text = (storage.foldername(name))[1]
);

-- Owner-only INSERT
create policy "contract_reviews_owner_insert"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'contract-reviews'
  and auth.uid()::text = (storage.foldername(name))[1]
);

-- Owner-only DELETE
create policy "contract_reviews_owner_delete"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'contract-reviews'
  and auth.uid()::text = (storage.foldername(name))[1]
);
