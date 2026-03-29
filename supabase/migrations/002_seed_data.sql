-- ============================================================================
-- Advocat App — Seed Data
-- Migration 002: Sulga demo case and sample deadlines
--
-- NOTE: This seed data uses fixed UUIDs so it can be referenced consistently.
-- The demo user ID must match an auth.users entry. In development you can
-- create a test user in the Supabase dashboard first, then replace the UUID
-- below. For local dev with `supabase start`, this will auto-insert.
-- ============================================================================

-- --------------------------------------------------------------------------
-- 0. Create a demo auth user (works with supabase local dev)
--    In production, remove this block — users sign up via the app.
-- --------------------------------------------------------------------------

-- We use a deterministic UUID for the demo user
do $$
begin
  -- Only insert if running in local dev (auth.users is writable locally)
  if not exists (select 1 from auth.users where id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890') then
    insert into auth.users (
      id,
      instance_id,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_user_meta_data,
      created_at,
      updated_at,
      aud,
      role
    ) values (
      'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
      '00000000-0000-0000-0000-000000000000',
      'dmitri.sulga@example.com',
      crypt('demo-password-123', gen_salt('bf')),
      now(),
      '{"full_name": "Dmitri Sulga"}'::jsonb,
      '2025-01-15T00:00:00Z',
      now(),
      'authenticated',
      'authenticated'
    );
  end if;
end $$;

-- --------------------------------------------------------------------------
-- 1. USER PROFILE
-- --------------------------------------------------------------------------

insert into public.users (
  id, full_name, email, phone,
  preferred_language, subscription_tier, subscription_expires_at,
  created_at
) values (
  'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
  'Dmitri Sulga',
  'dmitri.sulga@example.com',
  '+358 40 123 4567',
  'en',
  'premium',
  now() + interval '365 days',
  '2025-01-15T00:00:00Z'
)
on conflict (id) do update set
  full_name = excluded.full_name,
  phone = excluded.phone,
  subscription_tier = excluded.subscription_tier,
  subscription_expires_at = excluded.subscription_expires_at;

-- --------------------------------------------------------------------------
-- 2. CASES
-- --------------------------------------------------------------------------

-- Fixed case UUIDs
-- case-finland-001: 11111111-1111-1111-1111-111111111111
-- case-finland-002: 22222222-2222-2222-2222-222222222222
-- case-germany-003: 33333333-3333-3333-3333-333333333333
-- case-finland-004: 44444444-4444-4444-4444-444444444444

insert into public.cases (id, user_id, title, description, type, status, migri_reference_number, court_case_number, nationality, decision_date, appeal_deadline, hearing_date, ai_summary, created_at) values

('11111111-1111-1111-1111-111111111111',
 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
 'Deportation Order Appeal — Finland',
 'Appeal against deportation decision by Migri. Police issued the decision in Russian only, signed by wrong officer, and referenced "Soviet Union" as country of origin. Multiple procedural violations detected by AI analysis.',
 'deportation', 'appeal_filed',
 'UMA/2025/00431', 'HAO 2025/1234', 'Estonian',
 '2025-03-01', '2025-04-15', '2025-05-20',
 'Deportation case with 3 critical procedural errors: wrong language (Russian only), unauthorized signature, and factual error (Soviet Union reference). Strong grounds for appeal.',
 '2025-03-05T00:00:00Z'),

('22222222-2222-2222-2222-222222222222',
 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
 'Residence Permit Renewal',
 'Application for extended residence permit based on employment in Finland.',
 'residence_permit', 'pending_decision',
 'UMA/2025/00589', null, 'Estonian',
 null, null, null, null,
 '2025-02-10T00:00:00Z'),

('33333333-3333-3333-3333-333333333333',
 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
 'Unfair Dismissal — Germany',
 'Wrongful termination from employment without proper notice period. Employer failed to follow Kuendigungsschutzgesetz (Employment Protection Act) requirements. No prior warning was given and the works council was not consulted.',
 'labor_dispute', 'active',
 null, null, 'Estonian',
 null, null, null, null,
 '2025-04-01T00:00:00Z'),

('44444444-4444-4444-4444-444444444444',
 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
 'Illegal Eviction Notice — Finland',
 'Landlord issued an eviction notice without valid legal grounds and with insufficient notice period. The notice violates the Finnish Act on Residential Leases regarding tenant protections and required notice periods.',
 'tenant_rights', 'active',
 null, null, 'Estonian',
 null, null, null, null,
 '2025-04-10T00:00:00Z')

on conflict (id) do nothing;

-- --------------------------------------------------------------------------
-- 3. DOCUMENTS (for the main deportation case)
-- --------------------------------------------------------------------------

insert into public.documents (id, case_id, user_id, file_name, storage_path, mime_type, file_size_bytes, category, language, ocr_text, ai_summary, extracted_entities, processing_status, created_at) values

('d0c00001-0000-0000-0000-000000000001',
 '11111111-1111-1111-1111-111111111111',
 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
 'Police_Decision_Deportation.pdf',
 'a1b2c3d4-e5f6-7890-abcd-ef1234567890/11111111-1111-1111-1111-111111111111/Police_Decision_Deportation.pdf',
 'application/pdf', 245000,
 'decision', 'ru',
 E'HELSINGIN POLIISILAITOS\nРЕШЕНИЕ О ВЫСЫЛКЕ\n\nДело: UMA/2025/00431\nДата: 01.03.2025\n\nЛицо: Сулга Дмитрий\nГражданство: Советский Союз\n\nРЕШЕНИЕ:\nНа основании Закона об иностранцах (Ulkomaalaislaki) §143 принято решение о высылке вышеуказанного лица из Финляндии.\n\nОБОСНОВАНИЕ:\nЛицо не имеет действующего вида на жительство...\n\nПодпись: К. Виртанен\nСтарший констебль\nОтдел по делам иностранцев',
 'Deportation decision issued by Helsinki Police. Contains 3 critical procedural errors: wrong language (Russian instead of Finnish/English), signed by unauthorized officer, references non-existent country "Soviet Union".',
 '{"authority": "Helsinki Police Department", "decision_date": "2025-03-01", "appeal_deadline": "2025-04-15"}'::jsonb,
 'completed',
 '2025-03-05T00:00:00Z'),

('d0c00002-0000-0000-0000-000000000002',
 '11111111-1111-1111-1111-111111111111',
 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
 'Appeal_Draft_v2.pdf',
 'a1b2c3d4-e5f6-7890-abcd-ef1234567890/11111111-1111-1111-1111-111111111111/Appeal_Draft_v2.pdf',
 'application/pdf', 189000,
 'appeal', 'fi',
 null,
 'Draft appeal document addressing the three procedural violations found in the police decision. References Hallintolaki and Ulkomaalaislaki.',
 '{}'::jsonb,
 'completed',
 '2025-03-08T00:00:00Z'),

('d0c00003-0000-0000-0000-000000000003',
 '11111111-1111-1111-1111-111111111111',
 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
 'Medical_Certificate_2025.pdf',
 'a1b2c3d4-e5f6-7890-abcd-ef1234567890/11111111-1111-1111-1111-111111111111/Medical_Certificate_2025.pdf',
 'application/pdf', 98000,
 'medical', 'fi',
 null,
 'Medical certificate from Helsinki University Hospital confirming ongoing medical treatment. Relevant for humanitarian grounds.',
 '{}'::jsonb,
 'completed',
 '2025-03-10T00:00:00Z'),

('d0c00004-0000-0000-0000-000000000004',
 '11111111-1111-1111-1111-111111111111',
 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
 'Employment_Contract.pdf',
 'a1b2c3d4-e5f6-7890-abcd-ef1234567890/11111111-1111-1111-1111-111111111111/Employment_Contract.pdf',
 'application/pdf', 156000,
 'employment', 'en',
 null,
 'Full-time employment contract with a Finnish company. Supports the case for continued residency.',
 '{}'::jsonb,
 'completed',
 '2025-03-12T00:00:00Z'),

('d0c00005-0000-0000-0000-000000000005',
 '11111111-1111-1111-1111-111111111111',
 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
 'RIKU_Support_Letter.pdf',
 'a1b2c3d4-e5f6-7890-abcd-ef1234567890/11111111-1111-1111-1111-111111111111/RIKU_Support_Letter.pdf',
 'application/pdf', 67000,
 'evidence', 'fi',
 null,
 'Support letter from RIKU (Victim Support Finland) confirming participation in their program.',
 '{}'::jsonb,
 'completed',
 '2025-03-14T00:00:00Z')

on conflict (id) do nothing;

-- --------------------------------------------------------------------------
-- 4. DEADLINES
-- --------------------------------------------------------------------------

insert into public.deadlines (id, case_id, user_id, title, description, due_date, type, priority, status, source, source_document_id, created_at) values

('dead0001-0000-0000-0000-000000000001',
 '11111111-1111-1111-1111-111111111111',
 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
 'Lawyer consultation call',
 'Scheduled call with legal aid lawyer to review appeal strategy.',
 current_date + interval '7 days',
 'other', 'high', 'upcoming', 'manual', null,
 '2025-03-20T00:00:00Z'),

('dead0002-0000-0000-0000-000000000002',
 '11111111-1111-1111-1111-111111111111',
 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
 'Court response to appeal',
 'Expected date for Helsinki Administrative Court to acknowledge receipt of appeal and provide case number.',
 current_date + interval '14 days',
 'response_required', 'high', 'upcoming', 'ai_extracted',
 'd0c00001-0000-0000-0000-000000000001',
 '2025-03-05T00:00:00Z'),

('dead0003-0000-0000-0000-000000000003',
 '11111111-1111-1111-1111-111111111111',
 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
 'Appeal filing deadline',
 'Last day to file the appeal with Helsinki Administrative Court. 30 days from the date of the deportation decision.',
 '2025-04-15',
 'appeal', 'critical', 'upcoming', 'ai_extracted',
 'd0c00001-0000-0000-0000-000000000001',
 '2025-03-05T00:00:00Z'),

('dead0004-0000-0000-0000-000000000004',
 '11111111-1111-1111-1111-111111111111',
 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
 'Court hearing',
 'Oral hearing at Helsinki Administrative Court regarding the deportation appeal.',
 '2025-05-20',
 'hearing', 'critical', 'upcoming', 'manual', null,
 '2025-03-15T00:00:00Z'),

('dead0005-0000-0000-0000-000000000005',
 '22222222-2222-2222-2222-222222222222',
 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
 'Residence permit interview',
 'Interview at Migri Helsinki office.',
 current_date + interval '21 days',
 'hearing', 'medium', 'upcoming', 'manual', null,
 '2025-02-28T00:00:00Z')

on conflict (id) do nothing;

-- --------------------------------------------------------------------------
-- 5. CORRESPONDENCE
-- --------------------------------------------------------------------------

insert into public.correspondence (id, case_id, user_id, direction, channel, sender, recipient, subject, body, ai_summary, extracted_action_items, is_read, sent_at, created_at) values

('c0rr0001-0000-0000-0000-000000000001',
 '11111111-1111-1111-1111-111111111111',
 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
 'incoming', 'email',
 'helsinki.poliisi@poliisi.fi',
 'dmitri.sulga@example.com',
 'Deportation decision — Notification',
 E'Dear Mr. Sulga,\n\nPlease find attached the decision regarding your deportation case (UMA/2025/00431).\n\nYou have the right to appeal this decision within 30 days.\n\nHelsinki Police Department',
 'Official notification of deportation decision. Contains 30-day appeal deadline.',
 '["File appeal within 30 days", "Contact legal aid"]'::jsonb,
 true,
 '2025-03-01T00:00:00Z',
 '2025-03-01T00:00:00Z'),

('c0rr0002-0000-0000-0000-000000000002',
 '11111111-1111-1111-1111-111111111111',
 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
 'outgoing', 'email',
 'dmitri.sulga@example.com',
 'helsinki.hao@oikeus.fi',
 'Appeal against deportation decision UMA/2025/00431',
 E'To: Helsinki Administrative Court\n\nI hereby appeal the deportation decision UMA/2025/00431 issued on 01.03.2025 by the Helsinki Police Department.\n\nThe decision contains multiple procedural errors...',
 'Appeal filing sent to Helsinki Administrative Court.',
 '[]'::jsonb,
 true,
 '2025-03-10T00:00:00Z',
 '2025-03-10T00:00:00Z'),

('c0rr0003-0000-0000-0000-000000000003',
 '11111111-1111-1111-1111-111111111111',
 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
 'incoming', 'email',
 'helsinki.hao@oikeus.fi',
 'dmitri.sulga@example.com',
 'Case HAO 2025/1234 — Appeal received',
 E'Dear Mr. Sulga,\n\nYour appeal regarding deportation decision UMA/2025/00431 has been received and registered under case number HAO 2025/1234.\n\nYou will be notified of the hearing date.\n\nHelsinki Administrative Court',
 'Court confirmed receipt of appeal. Case number HAO 2025/1234 assigned.',
 '["Wait for hearing date notification"]'::jsonb,
 true,
 '2025-03-15T00:00:00Z',
 '2025-03-15T00:00:00Z'),

('c0rr0004-0000-0000-0000-000000000004',
 '11111111-1111-1111-1111-111111111111',
 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
 'incoming', 'email',
 'support@riku.fi',
 'dmitri.sulga@example.com',
 'RIKU victim support — Case referral',
 E'Dear Mr. Sulga,\n\nWe are writing to confirm your participation in the RIKU victim support program. We have provided a support letter to your legal representative.\n\nRIKU Finland',
 'RIKU confirms support program participation.',
 '[]'::jsonb,
 false,
 '2025-03-18T00:00:00Z',
 '2025-03-18T00:00:00Z')

on conflict (id) do nothing;

-- --------------------------------------------------------------------------
-- 6. CHAT MESSAGES (initial AI analysis conversation)
-- --------------------------------------------------------------------------

insert into public.chat_messages (id, case_id, user_id, role, content, created_at) values

('ca1a0001-0000-0000-0000-000000000001',
 '11111111-1111-1111-1111-111111111111',
 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
 'assistant',
 'Welcome, Dmitri. I have analyzed your deportation case (UMA/2025/00431). I found 3 critical procedural errors in the police decision that strengthen your appeal significantly.',
 '2025-03-05T10:00:00Z'),

('ca1a0002-0000-0000-0000-000000000002',
 '11111111-1111-1111-1111-111111111111',
 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
 'user',
 'What errors did you find?',
 '2025-03-05T10:01:00Z'),

('ca1a0003-0000-0000-0000-000000000003',
 '11111111-1111-1111-1111-111111111111',
 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
 'assistant',
 E'I found 3 critical errors in the police decision:\n\n1. WRONG LANGUAGE: The decision was issued in Russian only. Under Hallintolaki \u00A726 and Ulkomaalaislaki \u00A7203, decisions must be provided in Finnish, Swedish, or a language the person understands, with proper translation.\n\n2. UNAUTHORIZED SIGNATURE: The decision was signed by an officer who does not have the legal authority to issue deportation orders. Under Ulkomaalaislaki \u00A7152, only specifically authorized officials can sign such decisions.\n\n3. WRONG COUNTRY: The decision references "Soviet Union" as your country of origin. The Soviet Union ceased to exist in 1991. Your nationality is Estonian. This is a factual error that invalidates the basis of the decision.',
 '2025-03-05T10:02:00Z'),

('ca1a0004-0000-0000-0000-000000000004',
 '11111111-1111-1111-1111-111111111111',
 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
 'user',
 'Can you help me draft an appeal?',
 '2025-03-05T10:05:00Z'),

('ca1a0005-0000-0000-0000-000000000005',
 '11111111-1111-1111-1111-111111111111',
 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
 'assistant',
 E'Yes, I can help you draft an appeal. Based on the 3 errors found, your appeal has strong legal grounds. Here is what I recommend:\n\n- File with Helsinki Administrative Court (Helsingin hallinto-oikeus)\n- Reference all 3 procedural violations\n- Include your medical certificate and employment contract as evidence\n- Request an oral hearing\n\nThe appeal deadline is April 15, 2025 (30 days from the decision). I have drafted an appeal document that you can review in the Documents section.\n\nImportant: This is AI-generated legal guidance. Please consult with a licensed attorney before submitting any legal documents.',
 '2025-03-05T10:06:00Z')

on conflict (id) do nothing;

-- --------------------------------------------------------------------------
-- Done. Seed data loaded.
-- --------------------------------------------------------------------------
