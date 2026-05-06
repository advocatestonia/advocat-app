-- =====================================================================
-- Phase 2 Pkg 9 — Deadline Extractor RPC
--
-- Helper SECURITY DEFINER RPC `apply_deadline_extraction` accepts pre-
-- computed deadline rows from the `deadline-extractor` Edge Function and
-- upserts them into public.case_deadlines using the natural key
-- (case_id, anchor_key, deadline_at::date).
--
-- DESIGN NOTE — why pre-compute server-side AND keep an SQL upserter:
--   The architect doc (§5) discussed an in-database `pg_compute_deadline`
--   that mirrors the TS holiday-shift algorithm. We deliberately do NOT
--   ship that here — the FI/EE holiday list would have to be duplicated
--   between TS (`_shared/holidays_fi_ee.ts`) and SQL, doubling the drift
--   surface. Instead the Edge Function (which is the only writer of
--   case_deadlines through this RPC) uses the TS computeAbsoluteDeadline,
--   serializes the result (deadline_at, holiday_shifted, holiday_shift_note,
--   service_basis), and this RPC just upserts. Single source of truth lives
--   in `_shared/holiday_shift.ts`.
--
-- Spec source of truth: docs/architecture/phase2-pkg9-deadline-radar.md §5.
-- =====================================================================

-- ── 1. apply_deadline_extraction RPC ──────────────────────────────────
-- Accepts the Edge Function's output payload as a JSONB array of
-- pre-computed rows. Each row is upserted on (case_id, anchor_key,
-- deadline_at::date). Returns the inserted/updated ids.
--
-- Risk #5 (architect §11): if a row already exists with status='completed',
-- we KEEP the completed status (do not reopen). The merge check in the
-- ON CONFLICT branch enforces this.
--
-- Risk #1: priority='critical' from source='haiku_extract' is rejected by
-- the case_deadlines_critical_source_check constraint at the row level.
-- The RPC does not need its own check.
create or replace function public.apply_deadline_extraction(
    p_case_id uuid,
    p_rows    jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
    v_owner   uuid;
    v_inserted_ids uuid[] := array[]::uuid[];
    v_skipped_ids  uuid[] := array[]::uuid[];
    v_row jsonb;
    v_existing_id uuid;
    v_existing_status case_deadline_status;
    v_new_id  uuid;
begin
    if auth.uid() is null then
        raise exception 'unauthorized' using errcode = '42501';
    end if;

    select user_id into v_owner
      from public.user_cases
     where id = p_case_id;

    if v_owner is null or v_owner <> auth.uid() then
        raise exception 'forbidden' using errcode = '42501';
    end if;

    if jsonb_typeof(p_rows) <> 'array' then
        raise exception 'p_rows must be a jsonb array'
            using errcode = '22023';
    end if;

    for v_row in select * from jsonb_array_elements(p_rows)
    loop
        -- Look for an existing row on the natural key.
        select id, status
          into v_existing_id, v_existing_status
          from public.case_deadlines
         where case_id = p_case_id
           and anchor_key = (v_row->>'anchor_key')
           and deadline_at::date = ((v_row->>'deadline_at')::timestamptz)::date
         limit 1;

        if v_existing_id is not null then
            -- Risk #5: if completed, never reopen. Skip silently.
            if v_existing_status = 'completed' then
                v_skipped_ids := v_skipped_ids || v_existing_id;
                continue;
            end if;
            -- Otherwise update fields that may have moved (recompute of
            -- deadline_at after a service-clock correction, etc.) but keep
            -- status/completed_* untouched.
            update public.case_deadlines
               set title              = coalesce(v_row->>'title', title),
                   description        = coalesce(v_row->>'description', description),
                   statute_basis      = coalesce(v_row->>'statute_basis', statute_basis),
                   service_date       = coalesce((v_row->>'service_date')::date, service_date),
                   service_basis      = coalesce(v_row->>'service_basis', service_basis),
                   deadline_at        = coalesce((v_row->>'deadline_at')::timestamptz, deadline_at),
                   holiday_shifted    = coalesce((v_row->>'holiday_shifted')::boolean, holiday_shifted),
                   holiday_shift_note = coalesce(v_row->>'holiday_shift_note', holiday_shift_note),
                   priority           = coalesce((v_row->>'priority')::case_deadline_priority, priority),
                   source             = coalesce((v_row->>'source')::case_deadline_source, source),
                   source_doc_id      = coalesce((v_row->>'source_doc_id')::uuid, source_doc_id),
                   updated_at         = now()
             where id = v_existing_id;
            v_inserted_ids := v_inserted_ids || v_existing_id;
        else
            insert into public.case_deadlines (
                case_id, user_id, title, description, statute_basis,
                anchor_key, service_date, service_basis, deadline_at,
                holiday_shifted, holiday_shift_note, source, source_doc_id,
                priority, status
            ) values (
                p_case_id,
                v_owner,
                coalesce(v_row->>'title', 'Deadline'),
                v_row->>'description',
                v_row->>'statute_basis',
                v_row->>'anchor_key',
                (v_row->>'service_date')::date,
                v_row->>'service_basis',
                (v_row->>'deadline_at')::timestamptz,
                coalesce((v_row->>'holiday_shifted')::boolean, false),
                v_row->>'holiday_shift_note',
                coalesce((v_row->>'source')::case_deadline_source, 'haiku_extract'),
                (v_row->>'source_doc_id')::uuid,
                coalesce((v_row->>'priority')::case_deadline_priority, 'high'),
                'active'
            )
            returning id into v_new_id;
            v_inserted_ids := v_inserted_ids || v_new_id;
        end if;
    end loop;

    return jsonb_build_object(
        'created_or_updated', v_inserted_ids,
        'skipped_completed',  v_skipped_ids
    );
end;
$$;

alter function public.apply_deadline_extraction(uuid, jsonb)
    owner to postgres;

-- ── 2. PGRST schema cache reload ──────────────────────────────────────
notify pgrst, 'reload schema';
