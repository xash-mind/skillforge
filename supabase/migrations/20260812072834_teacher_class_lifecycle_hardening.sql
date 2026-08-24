-- TASK-004 hardening: prevent direct Data API bypasses and freeze completed evidence.

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

create or replace function private.enforce_classroom_record_integrity()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  session_state text;
begin
  if tg_table_name = 'lesson_sessions' then
    if tg_op = 'INSERT' then
      if new.state <> 'draft'
         or new.started_at is not null
         or new.attendance_marked_at is not null
         or new.evidence_uploaded_at is not null
         or new.homework_assigned_at is not null
         or new.ai_review_ready_at is not null
         or new.teacher_reviewed_at is not null
         or new.teacher_reviewed_by is not null
         or new.published_at is not null then
        raise exception 'lesson sessions must begin in draft without lifecycle timestamps'
          using errcode = '23514';
      end if;
      return new;
    end if;

    if new.organization_id <> old.organization_id
       or new.branch_id <> old.branch_id
       or new.class_id <> old.class_id
       or new.created_by <> old.created_by
       or new.session_date <> old.session_date then
      raise exception 'lesson session scope and attribution are immutable' using errcode = '23514';
    end if;

    if old.state = 'published' and new is distinct from old then
      raise exception 'published lesson sessions are immutable' using errcode = '23514';
    end if;

    if new.state = old.state then
      if new.started_at is distinct from old.started_at
         or new.attendance_marked_at is distinct from old.attendance_marked_at
         or new.evidence_uploaded_at is distinct from old.evidence_uploaded_at
         or new.homework_assigned_at is distinct from old.homework_assigned_at
         or new.ai_review_ready_at is distinct from old.ai_review_ready_at
         or new.teacher_reviewed_at is distinct from old.teacher_reviewed_at
         or new.teacher_reviewed_by is distinct from old.teacher_reviewed_by
         or new.published_at is distinct from old.published_at then
        raise exception 'lesson lifecycle timestamps are transition-controlled'
          using errcode = '23514';
      end if;
      return new;
    end if;

    if new.state = 'started' then
      if new.started_at is null
         or new.attendance_marked_at is distinct from old.attendance_marked_at
         or new.evidence_uploaded_at is distinct from old.evidence_uploaded_at
         or new.homework_assigned_at is distinct from old.homework_assigned_at
         or new.ai_review_ready_at is distinct from old.ai_review_ready_at
         or new.teacher_reviewed_at is distinct from old.teacher_reviewed_at
         or new.teacher_reviewed_by is distinct from old.teacher_reviewed_by
         or new.published_at is distinct from old.published_at then
        raise exception 'invalid lifecycle timestamp mutation while starting class'
          using errcode = '23514';
      end if;
    elsif new.state = 'attendance_marked' then
      if new.started_at is distinct from old.started_at
         or new.attendance_marked_at is null
         or new.evidence_uploaded_at is distinct from old.evidence_uploaded_at
         or new.homework_assigned_at is distinct from old.homework_assigned_at
         or new.ai_review_ready_at is distinct from old.ai_review_ready_at
         or new.teacher_reviewed_at is distinct from old.teacher_reviewed_at
         or new.teacher_reviewed_by is distinct from old.teacher_reviewed_by
         or new.published_at is distinct from old.published_at then
        raise exception 'invalid lifecycle timestamp mutation while marking attendance'
          using errcode = '23514';
      end if;
    elsif new.state = 'evidence_uploaded' then
      if new.started_at is distinct from old.started_at
         or new.attendance_marked_at is distinct from old.attendance_marked_at
         or new.evidence_uploaded_at is null
         or new.homework_assigned_at is distinct from old.homework_assigned_at
         or new.ai_review_ready_at is distinct from old.ai_review_ready_at
         or new.teacher_reviewed_at is distinct from old.teacher_reviewed_at
         or new.teacher_reviewed_by is distinct from old.teacher_reviewed_by
         or new.published_at is distinct from old.published_at then
        raise exception 'invalid lifecycle timestamp mutation while confirming evidence'
          using errcode = '23514';
      end if;
    elsif new.state = 'homework_assigned' then
      if new.started_at is distinct from old.started_at
         or new.attendance_marked_at is distinct from old.attendance_marked_at
         or new.evidence_uploaded_at is distinct from old.evidence_uploaded_at
         or new.homework_assigned_at is null
         or new.ai_review_ready_at is distinct from old.ai_review_ready_at
         or new.teacher_reviewed_at is distinct from old.teacher_reviewed_at
         or new.teacher_reviewed_by is distinct from old.teacher_reviewed_by
         or new.published_at is distinct from old.published_at then
        raise exception 'invalid lifecycle timestamp mutation while assigning homework'
          using errcode = '23514';
      end if;
    elsif new.state = 'ai_review_ready' then
      if new.started_at is distinct from old.started_at
         or new.attendance_marked_at is distinct from old.attendance_marked_at
         or new.evidence_uploaded_at is distinct from old.evidence_uploaded_at
         or new.homework_assigned_at is distinct from old.homework_assigned_at
         or new.ai_review_ready_at is null
         or new.teacher_reviewed_at is distinct from old.teacher_reviewed_at
         or new.teacher_reviewed_by is distinct from old.teacher_reviewed_by
         or new.published_at is distinct from old.published_at then
        raise exception 'invalid lifecycle timestamp mutation while preparing AI review'
          using errcode = '23514';
      end if;
    elsif new.state = 'teacher_reviewed' then
      if new.started_at is distinct from old.started_at
         or new.attendance_marked_at is distinct from old.attendance_marked_at
         or new.evidence_uploaded_at is distinct from old.evidence_uploaded_at
         or new.homework_assigned_at is distinct from old.homework_assigned_at
         or new.ai_review_ready_at is distinct from old.ai_review_ready_at
         or new.teacher_reviewed_at is null
         or new.teacher_reviewed_by is distinct from (select auth.uid())
         or new.published_at is distinct from old.published_at then
        raise exception 'invalid teacher review attribution'
          using errcode = '23514';
      end if;
    elsif new.state = 'published' then
      if new.started_at is distinct from old.started_at
         or new.attendance_marked_at is distinct from old.attendance_marked_at
         or new.evidence_uploaded_at is distinct from old.evidence_uploaded_at
         or new.homework_assigned_at is distinct from old.homework_assigned_at
         or new.ai_review_ready_at is distinct from old.ai_review_ready_at
         or new.teacher_reviewed_at is distinct from old.teacher_reviewed_at
         or new.teacher_reviewed_by is distinct from old.teacher_reviewed_by
         or new.published_at is null then
        raise exception 'invalid lifecycle timestamp mutation while publishing'
          using errcode = '23514';
      end if;
    end if;

  elsif tg_table_name = 'attendance_records' then
    if tg_op = 'UPDATE' and (
      new.organization_id <> old.organization_id
      or new.branch_id <> old.branch_id
      or new.class_id <> old.class_id
      or new.lesson_session_id <> old.lesson_session_id
      or new.organization_membership_id <> old.organization_membership_id
      or new.recorded_by <> old.recorded_by
    ) then
      raise exception 'attendance scope and attribution are immutable' using errcode = '23514';
    end if;

    select session.state into session_state
    from public.lesson_sessions session
    where session.organization_id = new.organization_id
      and session.branch_id = new.branch_id
      and session.class_id = new.class_id
      and session.id = new.lesson_session_id;

    if session_state is distinct from 'started' then
      raise exception 'attendance can only be recorded while the session is started'
        using errcode = '23514';
    end if;

  elsif tg_table_name = 'lesson_uploads' then
    if tg_op = 'UPDATE' and (
      new.organization_id <> old.organization_id
      or new.branch_id <> old.branch_id
      or new.class_id <> old.class_id
      or new.lesson_session_id <> old.lesson_session_id
      or new.kind <> old.kind
      or new.created_by <> old.created_by
    ) then
      raise exception 'upload scope and attribution are immutable' using errcode = '23514';
    end if;

    select session.state into session_state
    from public.lesson_sessions session
    where session.organization_id = new.organization_id
      and session.branch_id = new.branch_id
      and session.class_id = new.class_id
      and session.id = new.lesson_session_id;

    if session_state is distinct from 'attendance_marked' then
      raise exception 'class evidence can only change during the evidence upload step'
        using errcode = '23514';
    end if;

    if tg_op = 'INSERT' then
      if new.status <> 'pending' or new.retry_count <> 0 then
        raise exception 'new lesson uploads must begin pending'
          using errcode = '23514';
      end if;
    else
      if old.status = 'uploaded' then
        raise exception 'uploaded lesson evidence is immutable'
          using errcode = '23514';
      elsif old.status = 'pending' and new.status not in ('uploaded', 'failed') then
        raise exception 'pending uploads may only succeed or fail'
          using errcode = '23514';
      elsif old.status = 'failed' and (
        new.status <> 'pending'
        or new.retry_count <> old.retry_count + 1
        or new.storage_path = old.storage_path
      ) then
        raise exception 'failed uploads must enter a new pending retry attempt'
          using errcode = '23514';
      end if;
    end if;

    if new.status = 'uploaded' and not exists (
      select 1
      from storage.objects object
      where object.bucket_id = 'classroom-evidence'
        and object.name = new.storage_path
    ) then
      raise exception 'uploaded lesson evidence requires a matching storage object'
        using errcode = '23514';
    end if;

  elsif tg_table_name = 'homework_assignments' then
    if tg_op = 'UPDATE' and (
      new.organization_id <> old.organization_id
      or new.branch_id <> old.branch_id
      or new.class_id <> old.class_id
      or new.lesson_session_id <> old.lesson_session_id
      or new.created_by <> old.created_by
    ) then
      raise exception 'homework scope and attribution are immutable' using errcode = '23514';
    end if;

    select session.state into session_state
    from public.lesson_sessions session
    where session.organization_id = new.organization_id
      and session.branch_id = new.branch_id
      and session.class_id = new.class_id
      and session.id = new.lesson_session_id;

    if session_state is distinct from 'evidence_uploaded' then
      raise exception 'homework can only change during the homework step'
        using errcode = '23514';
    end if;
  end if;

  return new;
end;
$$;

revoke execute on function private.enforce_classroom_record_integrity()
  from public, anon, authenticated, service_role;
revoke execute on function private.enforce_lesson_session_transition()
  from public, anon, authenticated, service_role;

drop trigger if exists lesson_sessions_enforce_transition on public.lesson_sessions;
drop trigger if exists lesson_sessions_enforce_integrity on public.lesson_sessions;
drop trigger if exists attendance_records_enforce_integrity on public.attendance_records;
drop trigger if exists lesson_uploads_enforce_integrity on public.lesson_uploads;
drop trigger if exists homework_assignments_enforce_integrity on public.homework_assignments;

create trigger lesson_sessions_a_enforce_transition
before update of state on public.lesson_sessions
for each row execute function private.enforce_lesson_session_transition();
create trigger lesson_sessions_z_enforce_integrity
before insert or update on public.lesson_sessions
for each row execute function private.enforce_classroom_record_integrity();
create trigger attendance_records_enforce_integrity
before insert or update on public.attendance_records
for each row execute function private.enforce_classroom_record_integrity();
create trigger lesson_uploads_enforce_integrity
before insert or update on public.lesson_uploads
for each row execute function private.enforce_classroom_record_integrity();
create trigger homework_assignments_enforce_integrity
before insert or update on public.homework_assignments
for each row execute function private.enforce_classroom_record_integrity();

create or replace function private.can_read_classroom_evidence(
  organization_id_to_check bigint,
  branch_id_to_check bigint,
  class_id_to_check bigint,
  lesson_session_id_to_check bigint
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    private.is_class_teacher(
      organization_id_to_check,
      branch_id_to_check,
      class_id_to_check
    )
    and exists (
      select 1
      from public.lesson_sessions session
      where session.organization_id = organization_id_to_check
        and session.branch_id = branch_id_to_check
        and session.class_id = class_id_to_check
        and session.id = lesson_session_id_to_check
    );
$$;

create or replace function private.can_write_classroom_evidence(
  organization_id_to_check bigint,
  branch_id_to_check bigint,
  class_id_to_check bigint,
  lesson_session_id_to_check bigint
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    private.is_class_teacher(
      organization_id_to_check,
      branch_id_to_check,
      class_id_to_check
    )
    and exists (
      select 1
      from public.lesson_sessions session
      where session.organization_id = organization_id_to_check
        and session.branch_id = branch_id_to_check
        and session.class_id = class_id_to_check
        and session.id = lesson_session_id_to_check
        and session.state = 'attendance_marked'
    );
$$;

revoke execute on function private.can_read_classroom_evidence(bigint, bigint, bigint, bigint)
  from public, anon, authenticated, service_role;
revoke execute on function private.can_write_classroom_evidence(bigint, bigint, bigint, bigint)
  from public, anon, authenticated, service_role;

drop policy if exists classroom_evidence_select_teacher on storage.objects;
drop policy if exists classroom_evidence_insert_teacher on storage.objects;
drop policy if exists classroom_evidence_update_teacher on storage.objects;

create policy classroom_evidence_select_teacher
on storage.objects
for select
to authenticated
using (
  bucket_id = 'classroom-evidence'
  and array_length(storage.foldername(name), 1) >= 4
  and (storage.foldername(name))[1] ~ '^[0-9]+$'
  and (storage.foldername(name))[2] ~ '^[0-9]+$'
  and (storage.foldername(name))[3] ~ '^[0-9]+$'
  and (storage.foldername(name))[4] ~ '^[0-9]+$'
  and private.can_read_classroom_evidence(
    ((storage.foldername(name))[1])::bigint,
    ((storage.foldername(name))[2])::bigint,
    ((storage.foldername(name))[3])::bigint,
    ((storage.foldername(name))[4])::bigint
  )
);

create policy classroom_evidence_insert_teacher
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'classroom-evidence'
  and array_length(storage.foldername(name), 1) >= 4
  and (storage.foldername(name))[1] ~ '^[0-9]+$'
  and (storage.foldername(name))[2] ~ '^[0-9]+$'
  and (storage.foldername(name))[3] ~ '^[0-9]+$'
  and (storage.foldername(name))[4] ~ '^[0-9]+$'
  and private.can_write_classroom_evidence(
    ((storage.foldername(name))[1])::bigint,
    ((storage.foldername(name))[2])::bigint,
    ((storage.foldername(name))[3])::bigint,
    ((storage.foldername(name))[4])::bigint
  )
);
