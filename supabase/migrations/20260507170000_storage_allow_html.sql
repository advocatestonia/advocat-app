-- Allow text/html uploads to case-documents bucket.
-- The pdf-generator edge function uploads generated HTML documents; the bucket
-- previously only allowed pdf/image/word mime types which caused 502 errors.
update storage.buckets
set allowed_mime_types = array[
  'application/pdf',
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/heic',
  'application/msword',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'text/html',
  'text/plain'
]
where id = 'case-documents';
