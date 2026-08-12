-- TASK-004: guided teacher class lifecycle, recovery, and private classroom evidence.

alter table public.class_enrollments
  add constraint class_enrollments_scope_membership_key
  unique (organization_id, branch_id, class_id, organization_membership_id);

create table public.lesson_sessions (
  id bigint generated always as identity primary key,
  organization_id bigint not null,
  branch_id bigint not null,
  class_id bigint not null,
  state text not null default 'draft',
  title text,
  session_date date not null default current_date,
  started_at timestamptz,
  attendance_marked_at timestamptz,
  evidence_uploaded_at timestamptz,
  homework_assigned_at timestamptz,
  ai_review_ready_at timestamptz,
  teacher_reviewed_at timestamptz,
  teacher_reviewed_by uuid references public.profiles (id) on delete restrict,
  published_at timestamptz,
  created_by uuid not null references public.profiles (id) on delete restrict,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  constraint lesson_sessions_class_fkey foreign key (organization_id, branch_id, class_id)
    references public.classes (organization_id, branch_id, id) on delete restrict,
  constraint lesson_sessions_state_check check (
    state in (
      'draft',
      'started',
      'attendance_marked',
      'evidence_uploaded',
      'homework_assigned',
      'ai_review_ready',
      'teacher_reviewed',
      'published'
    )
  ),
  constraint lesson_sessions_title_length check (
    title is null or char_length(title) between 2 and 180
  ),
  constraint lesson_sessions_scope_id_key unique (organization_id, branch_id, class_id, id)
);

create unique index lesson_sessions_one_open_per_class_idx
  on public.lesson_sessions (class_id)
  where state <> 'published';
create index lesson_sessions_class_state_idx
  on public.lesson_sessions (organization_id, branch_id, class_id, state);
create index lesson_sessions_created_by_idx on public.lesson_sessions (created_by);
create index lesson_sessions_teacher_reviewed_by_idx on public.lesson_sessions (teacher_reviewed_by);

create table public.attendance_records (
  id bigint generated always as identity primary key,
  organization_id bigint not null,
  branch_id bigint not null,
  class_id bigint not null,
  lesson_session_id bigint not null,
  organization_membership_id bigint not null,
  status text not null,
  note text,
  recorded_by uuid not null references public.profiles (id) on delete restrict,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  constraint attendance_records_session_fkey foreign key (
    organization_id,
    branch_id,
    class_id,
    lesson_session_id
  ) references public.lesson_sessions (organization_id, branch_id, class_id, id) on delete restrict,
  constraint attendance_records_enrollment_fkey foreign key (
    organization_id,
    branch_id,
    class_id,
    organization_membership_id
  ) references public.class_enrollments (
    organization_id,
    branch_id,
    class_id,
    organization_membership_id
  ) on delete restrict,
  constraint attendance_records_status_check check (
    status in ('present', 'absent', 'late', 'excused')
  ),
  constraint attendance_records_note_length check (
    note is null or char_length(note) between 1 and 500
  ),
  constraint attendance_records_session_membership_key unique (
    lesson_session_id,
    organization_membership_id
  )
);

create index attendance_records_session_idx
  on public.attendance_records (organization_id, branch_id, class_id, lesson_session_id);
create index attendance_records_membership_idx
  on public.attendance_records (organization_membership_id);
create index attendance_records_recorded_by_idx on public.attendance_records (recorded_by);

create table public.lesson_uploads (
  id bigint generated always as identity primary key,
  organization_id bigint not null,
  branch_id bigint not null,
  class_id bigint not null,
  lesson_session_id bigint not null,
  kind text not null,
  storage_path text not null,
  original_name text not null,
  mime_type text not null,
  size_bytes bigint not null,
  status text not null default 'pending',
  failure_message text,
  retry_count integer not null default 0,
  uploaded_at timestamptz,
  created_by uuid not null references public.profiles (id) on delete restrict,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  constraint lesson_uploads_session_fkey foreign key (
    organization_id,
    branch_id,
    class_id,
    lesson_session_id
  ) references public.lesson_sessions (organization_id, branch_id, class_id, id) on delete restrict,
  constraint lesson_uploads_kind_check check (kind in ('transcript', 'resource')),
  constraint lesson_uploads_original_name_length check (char_length(original_name) between 1 and 180),
  constraint lesson_uploads_mime_type_length check (char_length(mime_type) between 1 and 180),
  constraint lesson_uploads_size_check check (size_bytes between 1 and 10485760),
  constraint lesson_uploads_status_check check (status in ('pending', 'uploaded', 'failed')),
  constraint lesson_uploads_failure_length check (
    failure_message is null or char_length(failure_message) between 1 and 500
  ),
  constraint lesson_uploads_retry_nonnegative check (retry_count >= 0),
  constraint lesson_uploads_uploaded_at_check check (
    (status = 'uploaded' and uploaded_at is not null and failure_message is null)
    or (status = 'failed' and failure_message is not null and uploaded_at is null)
    or (status = 'pending' and uploaded_at is null and failure_message is null)
  ),
  constraint lesson_uploads_storage_path_key unique (storage_path)
);

create index lesson_uploads_session_kind_status_idx
  on public.lesson_uploads (organization_id, branch_id, class_id, lesson_session_id, kind, status);
create index lesson_uploads_created_by_idx on public.lesson_uploads (created_by);

create table public.homework_assignments (
  id bigint generated always as identity primary key,
  organization_id bigint not null,
  branch_id bigint not null,
  class_id bigint not null,
  lesson_session_id bigint not null,
  title text not null,
  instructions text,
  due_at timestamptz,
  created_by uuid not null references public.profiles (id) on delete restrict,
  created_at timestamptz not null default statement_timestamp(),
  updated_at timestamptz not null default statement_timestamp(),
  constraint homework_assignments_session_fkey foreign key (
    organization_id,
    branch_id,
    class_id,
    lesson_session_id
  ) references public.lesson_sessions (organization_id, branch_id, class_id, id) on delete restrict,
  constraint homework_assignments_title_length check (char_length(title) between 2 and 180),
  constraint homework_assignments_instructions_length check (
    instructions is null or char_length(instructions) between 1 and 4000
  )
);

create index homework_assignments_session_idx
  on public.homework_assignments (organization_id, branch_id, class_id, lesson_session_id);
create index homework_assignments_created_by_idx on public.homework_assignments (created_by);

create or replace function private.enforce_classroom_record_integrity()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_table_name = 'lesson_sessions' then
    if new.organization_id <> old.organization_id
       or new.branch_id <> old.branch_id
       or new.class_id <> old.class_id
       or new.created_by <> old.created_by
       or new.session_date <> old.session_date then
      raise exception 'lesson session scope and attribution are immutable' using errcode = '23514';
    end if;
  elsif tg_table_name = 'attendance_records' then
    if new.organization_id <> old.organization_id
       or new.branch_id <> old.branch_id
       or new.class_id <> old.class_id
       or new.lesson_session_id <> old.lesson_session_id
       or new.organization_membership_id <> old.organization_membership_id
       or new.recorded_by <> old.recorded_by then
      raise exception 'attendance scope and attribution are immutable' using errcode = '23514';
    end if;
  elsif tg_table_name = 'lesson_uploads' then
    if new.organization_id <> old.organization_id
       or new.branch_id <> old.branch_id
       or new.class_id <> old.class_id
       or new.lesson_session_id <> old.lesson_session_id
       or new.kind <> old.kind
       or new.created_by <> old.created_by then
      raise exception 'upload scope and attribution are immutable' using errcode = '23514';
    end if;
  elsif tg_table_name = 'homework_assignments' then
    if new.organization_id <> old.organization_id
       or new.branch_id <> old.branch_id
       or new.class_id <> old.class_id
       or new.lesson_session_id <> old.lesson_session_id
       or new.created_by <> old.created_by then
      raise exception 'homework scope and attribution are immutable' using errcode = '23514';
    end if;
  end if;
  return new;
end;
$$;

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
    new.started_at := coalesce(new.started_at, statement_timestamp());
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

create or replace function public.start_lesson_session(
  class_id_input bigint,
  title_input text default null
)
returns bigint
language plpgsql
security invoker
set search_path = ''
as $$
declare
  selected_class public.classes%rowtype;
  created_session_id bigint;
begin
  select class_row.* into selected_class
  from public.classes class_row
  where class_row.id = class_id_input;

  if not found then
    raise exception 'class is unavailable' using errcode = '42501';
  end if;

  insert into public.lesson_sessions (
    organization_id,
    branch_id,
    class_id,
    title,
    created_by
  ) values (
    selected_class.organization_id,
    selected_class.branch_id,
    selected_class.id,
    nullif(btrim(title_input), ''),
    (select auth.uid())
  ) returning id into created_session_id;

  update public.lesson_sessions
  set state = 'started'
  where id = created_session_id;

  return created_session_id;
end;
$$;

create or replace function public.advance_lesson_session(
  lesson_session_id_input bigint,
  expected_state_input text,
  next_state_input text
)
returns text
language plpgsql
security invoker
set search_path = ''
as $$
declare
  resolved_state text;
begin
  update public.lesson_sessions
  set state = next_state_input
  where id = lesson_session_id_input
    and state = expected_state_input
  returning state into resolved_state;

  if not found then
    raise exception 'session state changed or the session is outside your teacher scope'
      using errcode = '40001';
  end if;

  return resolved_state;
end;
$$;

revoke execute on function private.enforce_classroom_record_integrity()
  from public, anon, authenticated, service_role;
revoke execute on function private.enforce_lesson_session_transition()
  from public, anon, authenticated, service_role;
revoke execute on function public.start_lesson_session(bigint, text)
  from public, anon, authenticated, service_role;
revoke execute on function public.advance_lesson_session(bigint, text, text)
  from public, anon, authenticated, service_role;
grant execute on function public.start_lesson_session(bigint, text) to authenticated;
grant execute on function public.advance_lesson_session(bigint, text, text) to authenticated;

create trigger lesson_sessions_enforce_transition
before update of state on public.lesson_sessions
for each row execute function private.enforce_lesson_session_transition();

create trigger lesson_sessions_enforce_integrity
before update on public.lesson_sessions
for each row execute function private.enforce_classroom_record_integrity();
create trigger attendance_records_enforce_integrity
before update on public.attendance_records
for each row execute function private.enforce_classroom_record_integrity();
create trigger lesson_uploads_enforce_integrity
before update on public.lesson_uploads
for each row execute function private.enforce_classroom_record_integrity();
create trigger homework_assignments_enforce_integrity
before update on public.homework_assignments
for each row execute function private.enforce_classroom_record_integrity();

create trigger lesson_sessions_set_updated_at
before update on public.lesson_sessions
for each row execute function private.set_updated_at();
create trigger attendance_records_set_updated_at
before update on public.attendance_records
for each row execute function private.set_updated_at();
create trigger lesson_uploads_set_updated_at
before update on public.lesson_uploads
for each row execute function private.set_updated_at();
create trigger homework_assignments_set_updated_at
before update on public.homework_assignments
for each row execute function private.set_updated_at();

create trigger lesson_sessions_write_audit
after insert or update on public.lesson_sessions
for each row execute function private.write_audit_event('organization_id', 'branch_id', 'id');
create trigger attendance_records_write_audit
after insert or update on public.attendance_records
for each row execute function private.write_audit_event('organization_id', 'branch_id', 'id');
create trigger lesson_uploads_write_audit
after insert or update on public.lesson_uploads
for each row execute function private.write_audit_event('organization_id', 'branch_id', 'id');
create trigger homework_assignments_write_audit
after insert or update on public.homework_assignments
for each row execute function private.write_audit_event('organization_id', 'branch_id', 'id');

alter table public.lesson_sessions enable row level security;
alter table public.lesson_sessions force row level security;
alter table public.attendance_records enable row level security;
alter table public.attendance_records force row level security;
alter table public.lesson_uploads enable row level security;
alter table public.lesson_uploads force row level security;
alter table public.homework_assignments enable row level security;
alter table public.homework_assignments force row level security;

create policy lesson_sessions_select_teacher_manager
on public.lesson_sessions
for select
to authenticated
using (
  (select private.is_class_teacher(organization_id, branch_id, class_id))
  or (select private.can_manage_branch(organization_id, branch_id))
);
create policy lesson_sessions_insert_teacher
on public.lesson_sessions
for insert
to authenticated
with check (
  created_by = (select auth.uid())
  and (select private.is_class_teacher(organization_id, branch_id, class_id))
);
create policy lesson_sessions_update_teacher
on public.lesson_sessions
for update
to authenticated
using ((select private.is_class_teacher(organization_id, branch_id, class_id)))
with check ((select private.is_class_teacher(organization_id, branch_id, class_id)));

create policy attendance_records_select_teacher_manager
on public.attendance_records
for select
to authenticated
using (
  (select private.is_class_teacher(organization_id, branch_id, class_id))
  or (select private.can_manage_branch(organization_id, branch_id))
);
create policy attendance_records_insert_teacher
on public.attendance_records
for insert
to authenticated
with check (
  recorded_by = (select auth.uid())
  and (select private.is_class_teacher(organization_id, branch_id, class_id))
);
create policy attendance_records_update_teacher
on public.attendance_records
for update
to authenticated
using ((select private.is_class_teacher(organization_id, branch_id, class_id)))
with check ((select private.is_class_teacher(organization_id, branch_id, class_id)));

create policy lesson_uploads_select_teacher_manager
on public.lesson_uploads
for select
to authenticated
using (
  (select private.is_class_teacher(organization_id, branch_id, class_id))
  or (select private.can_manage_branch(organization_id, branch_id))
);
create policy lesson_uploads_insert_teacher
on public.lesson_uploads
for insert
to authenticated
with check (
  created_by = (select auth.uid())
  and (select private.is_class_teacher(organization_id, branch_id, class_id))
);
create policy lesson_uploads_update_teacher
on public.lesson_uploads
for update
to authenticated
using ((select private.is_class_teacher(organization_id, branch_id, class_id)))
with check ((select private.is_class_teacher(organization_id, branch_id, class_id)));

create policy homework_assignments_select_teacher_manager
on public.homework_assignments
for select
to authenticated
using (
  (select private.is_class_teacher(organization_id, branch_id, class_id))
  or (select private.can_manage_branch(organization_id, branch_id))
);
create policy homework_assignments_insert_teacher
on public.homework_assignments
for insert
to authenticated
with check (
  created_by = (select auth.uid())
  and (select private.is_class_teacher(organization_id, branch_id, class_id))
);
create policy homework_assignments_update_teacher
on public.homework_assignments
for update
to authenticated
using ((select private.is_class_teacher(organization_id, branch_id, class_id)))
with check ((select private.is_class_teacher(organization_id, branch_id, class_id)));

revoke all on table public.lesson_sessions from public, anon, authenticated;
revoke all on table public.attendance_records from public, anon, authenticated;
revoke all on table public.lesson_uploads from public, anon, authenticated;
revoke all on table public.homework_assignments from public, anon, authenticated;
grant select, insert, update on table public.lesson_sessions to authenticated;
grant select, insert, update on table public.attendance_records to authenticated;
grant select, insert, update on table public.lesson_uploads to authenticated;
grant select, insert, update on table public.homework_assignments to authenticated;
grant usage, select on sequence public.lesson_sessions_id_seq to authenticated;
grant usage, select on sequence public.attendance_records_id_seq to authenticated;
grant usage, select on sequence public.lesson_uploads_id_seq to authenticated;
grant usage, select on sequence public.homework_assignments_id_seq to authenticated;

grant all on table public.lesson_sessions to service_role;
grant all on table public.attendance_records to service_role;
grant all on table public.lesson_uploads to service_role;
grant all on table public.homework_assignments to service_role;
grant all on sequence public.lesson_sessions_id_seq to service_role;
grant all on sequence public.attendance_records_id_seq to service_role;
grant all on sequence public.lesson_uploads_id_seq to service_role;
grant all on sequence public.homework_assignments_id_seq to service_role;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'classroom-evidence',
  'classroom-evidence',
  false,
  10485760,
  array[
    'application/pdf',
    'audio/mpeg',
    'audio/mp4',
    'audio/wav',
    'image/jpeg',
    'image/png',
    'text/plain',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation'
  ]
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

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
  and (select private.is_class_teacher(
    ((storage.foldername(name))[1])::bigint,
    ((storage.foldername(name))[2])::bigint,
    ((storage.foldername(name))[3])::bigint
  ))
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
  and (select private.is_class_teacher(
    ((storage.foldername(name))[1])::bigint,
    ((storage.foldername(name))[2])::bigint,
    ((storage.foldername(name))[3])::bigint
  ))
);

create policy classroom_evidence_update_teacher
on storage.objects
for update
to authenticated
using (
  bucket_id = 'classroom-evidence'
  and array_length(storage.foldername(name), 1) >= 4
  and (storage.foldername(name))[1] ~ '^[0-9]+$'
  and (storage.foldername(name))[2] ~ '^[0-9]+$'
  and (storage.foldername(name))[3] ~ '^[0-9]+$'
  and (select private.is_class_teacher(
    ((storage.foldername(name))[1])::bigint,
    ((storage.foldername(name))[2])::bigint,
    ((storage.foldername(name))[3])::bigint
  ))
)
with check (
  bucket_id = 'classroom-evidence'
  and array_length(storage.foldername(name), 1) >= 4
  and (storage.foldername(name))[1] ~ '^[0-9]+$'
  and (storage.foldername(name))[2] ~ '^[0-9]+$'
  and (storage.foldername(name))[3] ~ '^[0-9]+$'
  and (select private.is_class_teacher(
    ((storage.foldername(name))[1])::bigint,
    ((storage.foldername(name))[2])::bigint,
    ((storage.foldername(name))[3])::bigint
  ))
);
