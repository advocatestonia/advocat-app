-- 20260530100000_case_documents_bucket_private.sql
-- ---------------------------------------------------------------------------
-- SECURITY (broken access control / IDOR on client legal documents).
--
-- The `case-documents` storage bucket was `public = true`. A public bucket
-- serves every object through /storage/v1/object/public/<bucket>/<path>
-- WITHOUT authentication — the owner-scoped RLS policies on storage.objects
-- (which require (storage.foldername(name))[1] = auth.uid()) are bypassed
-- entirely for the public endpoint. Verified live 2026-05-30: a user's
-- private case document was served HTTP 200 with no Authorization header.
--
-- This bucket holds uploaded client case files (PDFs, scans of legal
-- correspondence) — i.e. the most sensitive PII / attorney-client material in
-- the product. Anyone who obtains a path (UUID leakage via logs, referrer
-- headers, shared links, or the case_documents.storage_path column) could
-- read another user's files.
--
-- The application code is ALREADY written for a private bucket: document
-- downloads use createSignedUrl (supabase_service.dart:280,
-- contract-review/pdf-generator edge fns) and the avatar path in
-- edit_profile_screen.dart explicitly notes "this private bucket" and signs a
-- long-lived URL. The `public = true` flag is a stale dev-time leftover that
-- contradicts the code's own assumptions; flipping it to false closes the
-- unauthenticated read path while authenticated access (via the existing,
-- correct RLS) and signed URLs keep working unchanged.
--
-- `documents` and `contract-reviews` are already private; `org-branding`
-- stays public (logos are intentionally world-readable). Only case-documents
-- is corrected here.
--
-- Idempotent.
-- ---------------------------------------------------------------------------

update storage.buckets
set public = false
where id = 'case-documents';
