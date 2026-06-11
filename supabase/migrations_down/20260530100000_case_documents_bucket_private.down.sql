-- ROLLBACK for 20260530100000_case_documents_bucket_private.sql
-- Re-flips the case-documents bucket back to public. Safe textual inverse.
-- WARNING: this REOPENS the unauthenticated-read IDOR on client legal files.
-- Only use if flipping to private broke an authenticated download path that
-- was (incorrectly) relying on the public endpoint.
update storage.buckets
set public = true
where id = 'case-documents';
