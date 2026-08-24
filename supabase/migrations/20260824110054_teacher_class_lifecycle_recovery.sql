-- TASK-004 recovery: make interrupted upload finalization deterministic and cover enrollment lookups.

create index if not exists attendance_records_enrollment_scope_idx
  on public.attendance_records (
    organization_id,
    branch_id,
    class_id,
    organization_membership_id
  );

create unique index if not exists lesson_uploads_one_pending_per_kind_idx
  on public.lesson_uploads (lesson_session_id, kind)
  where status = 'pending';

create or replace function private.enforce_lesson_session_transition()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  expected_next_state text;
  enrolled_count integer;
  attendance_count integer;
begin
  if new.state = old.state then
    return new;
  end if;

  expected_next_state := case old.state
    when 'draft' then 'started'
    when 'started' then 'attendance_marked'
    when 'attendance_marked' then 'evidence_uploaded'
    when 'evidence_uploaded' then 'homework_assigned'
    when 'homework_assigned' then 'ai_review_ready'
    when 'ai_review_ready' then 'teacher_reviewed'
    when 'teacher_reviewed' then 'published'
    else null
  end;

  if expected_next_state is null or new.state <> expected_next_state then
    raise exception 'invalid lesson session transition: % -> %', old.state, new.state
      using errcode = '23514';
  end if;

  if new.state = 'started' then
    new.started_at := statement_timestamp();
  elsif new.state = 'attendance_marked' then
    select count(*) into enrolled_count
    from public.class_enrollments enrollment
    where enrollment.organization_id = old.organization_id
      and enrollment.branch_id = old.branch_id
      and enrollment.class_id = old.class_id
      and enrollment.status = 'enrolled';

    select count(*) into attendance_count
    from public.attendance_records attendance
    where attendance.organization_id = old.organization_id
      and attendance.branch_id = old.branch_id
      and attendance.class_id = old.class_id
      and attendance.lesson_session_id = old.id;

    if enrolled_count = 0 then
      raise exception 'record at least one enrolled student before marking attendance complete'
        using errcode = '23514';
    end if;

    if attendance_count <> enrolled_count then
      raise exception 'record attendance for every enrolled student before continuing'
        using errcode = '23514';
    end if;

    new.attendance_marked_at := statement_timestamp();
  elsif new.state = 'evidence_uploaded' then
    if exists (
      select 1 from public.lesson_uploads upload
      where upload.lesson_session_id = old.id
        and upload.status = 'pending'
    ) then
      raise exception 'resolve pending class evidence before confirming class evidence'
        using errcode = '23514';
    end if;

    if not exists (
      select 1 from public.lesson_uploads upload
      where upload.lesson_session_id = old.id
        and upload.kind = 'transcript'
        and upload.status = 'uploaded'
    ) then
      raise exception 'upload a transcript before confirming class evidence'
        using errcode = '23514';
    end if;

    if not exists (
      select 1 from public.lesson_uploads upload
      where upload.lesson_session_id = old.id
        and upload.kind = 'resource'
        and upload.status = 'uploaded'
    ) then
      raise exception 'upload a class resource before confirming class evidence'
        using errcode = '23514';
    end if;

    new.evidence_uploaded_at := statement_timestamp();
  elsif new.state = 'homework_assigned' then
    if not exists (
      select 1 from public.homework_assignments homework
      where homework.lesson_session_id = old.id
    ) then
      raise exception 'assign homework before continuing'
        using errcode = '23514';
    end if;
    new.homework_assigned_at := statement_timestamp();
  elsif new.state = 'ai_review_ready' then
    new.ai_review_ready_at := statement_timestamp();
  elsif new.state = 'teacher_reviewed' then
    new.teacher_reviewed_at := statement_timestamp();
    new.teacher_reviewed_by := (select auth.uid());
  elsif new.state = 'published' then
    if old.teacher_reviewed_at is null or old.teacher_reviewed_by is null then
      raise exception 'teacher review is required before publishing'
        using errcode = '23514';
    end if;
    new.published_at := statement_timestamp();
  end if;

  return new;
end;
$$;

revoke execute on function private.enforce_lesson_session_transition()
  from public, anon, authenticated, service_role;
