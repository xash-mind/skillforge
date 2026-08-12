-- TASK-004 rollback-safe teacher lifecycle, transition, retry, and branch-isolation proof.
begin;

insert into auth.users (id, email, raw_user_meta_data)
values
  ('30000000-0000-0000-0000-000000000001', 'lifecycle-platform@example.invalid', '{"display_name":"Lifecycle Platform"}'::jsonb),
  ('30000000-0000-0000-0000-000000000002', 'lifecycle-owner@example.invalid', '{"display_name":"Lifecycle Owner"}'::jsonb),
  ('30000000-0000-0000-0000-000000000003', 'lifecycle-teacher-main@example.invalid', '{"display_name":"Main Teacher"}'::jsonb),
  ('30000000-0000-0000-0000-000000000004', 'lifecycle-teacher-west@example.invalid', '{"display_name":"West Teacher"}'::jsonb),
  ('30000000-0000-0000-0000-000000000005', 'lifecycle-student@example.invalid', '{"display_name":"Main Student"}'::jsonb);

insert into private.platform_role_assignments (user_id)
values ('30000000-0000-0000-0000-000000000001');

set local role authenticated;
select set_config('request.jwt.claim.role', 'authenticated', true);
select set_config('request.jwt.claim.sub', '30000000-0000-0000-0000-000000000001', true);

insert into public.organizations (name, slug, region_code, created_by)
values ('Lifecycle Fixture', 'lifecycle-fixture', 'IN', '30000000-0000-0000-0000-000000000001');

insert into public.branches (organization_id, name, code, timezone, created_by)
select organization.id, fixture.name, fixture.code, 'Asia/Kolkata', '30000000-0000-0000-0000-000000000001'
from public.organizations organization
cross join (values ('Main Campus', 'MAIN'), ('West Campus', 'WEST')) as fixture(name, code)
where organization.slug = 'lifecycle-fixture';

insert into public.organization_memberships (organization_id, user_id, status, joined_at, created_by)
select organization.id, fixture.user_id, 'active', statement_timestamp(), '30000000-0000-0000-0000-000000000001'
from public.organizations organization
cross join (
  values
    ('30000000-0000-0000-0000-000000000002'::uuid),
    ('30000000-0000-0000-0000-000000000003'::uuid),
    ('30000000-0000-0000-0000-000000000004'::uuid),
    ('30000000-0000-0000-0000-000000000005'::uuid)
) as fixture(user_id)
where organization.slug = 'lifecycle-fixture';

insert into public.branch_memberships (organization_id, organization_membership_id, branch_id, created_by)
select membership.organization_id, membership.id, branch.id, '30000000-0000-0000-0000-000000000001'
from public.organization_memberships membership
join public.branches branch
  on branch.organization_id = membership.organization_id
 and branch.code = case
   when membership.user_id in ('30000000-0000-0000-0000-000000000003', '30000000-0000-0000-0000-000000000005') then 'MAIN'
   else 'WEST'
 end
where membership.user_id <> '30000000-0000-0000-0000-000000000002';

insert into public.role_assignments (organization_id, organization_membership_id, branch_id, role, assigned_by)
select membership.organization_id, membership.id, branch.id, fixture.role, '30000000-0000-0000-0000-000000000001'
from (
  values
    ('30000000-0000-0000-0000-000000000002'::uuid, 'organization_owner', null::text),
    ('30000000-0000-0000-0000-000000000003'::uuid, 'teacher', 'MAIN'),
    ('30000000-0000-0000-0000-000000000004'::uuid, 'teacher', 'WEST'),
    ('30000000-0000-0000-0000-000000000005'::uuid, 'student', 'MAIN')
) as fixture(user_id, role, branch_code)
join public.organization_memberships membership on membership.user_id = fixture.user_id
left join public.branches branch
  on branch.organization_id = membership.organization_id
 and branch.code = fixture.branch_code;

select set_config('request.jwt.claim.sub', '30000000-0000-0000-0000-000000000002', true);

with bundle as (
  select * from public.create_custom_syllabus_bundle(
    (select id from public.organizations where slug = 'lifecycle-fixture'),
    'LIFE-MATH-10', 'Lifecycle Mathematics', 'Lifecycle fixture', '2026-27',
    'ALG.1', 'Solve linear equations', 'Solve one-variable equations.'
  )
)
insert into public.subjects (organization_id, syllabus_id, syllabus_version_id, code, name, created_by)
select (select id from public.organizations where slug = 'lifecycle-fixture'), syllabus_id,
       syllabus_version_id, 'LIFE-MATH', 'Mathematics', '30000000-0000-0000-0000-000000000002'
from bundle;

select * from public.create_class_bundle(
  (select id from public.organizations where slug = 'lifecycle-fixture'),
  (select id from public.branches where code = 'MAIN' and organization_id = (select id from public.organizations where slug = 'lifecycle-fixture')),
  (select id from public.subjects where code = 'LIFE-MATH' and organization_id = (select id from public.organizations where slug = 'lifecycle-fixture')),
  (select objective.id from public.syllabus_objectives objective join public.subjects subject on subject.syllabus_id = objective.syllabus_id and subject.syllabus_version_id = objective.syllabus_version_id where subject.code = 'LIFE-MATH' and subject.organization_id = (select id from public.organizations where slug = 'lifecycle-fixture') limit 1),
  'LIFE-MATH-A', 'Lifecycle Mathematics A', '2026-27', 1::smallint, '09:00'::time, '10:00'::time,
  'Room 1', '2026-06-01'::date, null::date
);

insert into public.class_teachers (organization_id, branch_id, class_id, organization_membership_id, created_by)
select class_row.organization_id, class_row.branch_id, class_row.id, membership.id,
       '30000000-0000-0000-0000-000000000002'
from public.classes class_row
join public.organization_memberships membership on membership.user_id = '30000000-0000-0000-0000-000000000003'
where class_row.code = 'LIFE-MATH-A';

insert into public.class_enrollments (organization_id, branch_id, class_id, organization_membership_id, created_by)
select class_row.organization_id, class_row.branch_id, class_row.id, membership.id,
       '30000000-0000-0000-0000-000000000002'
from public.classes class_row
join public.organization_memberships membership on membership.user_id = '30000000-0000-0000-0000-000000000005'
where class_row.code = 'LIFE-MATH-A';

select set_config('request.jwt.claim.sub', '30000000-0000-0000-0000-000000000003', true);

select public.start_lesson_session(
  (select id from public.classes where code = 'LIFE-MATH-A'),
  'Lifecycle verification class'
);

do $$
declare session_id bigint;
begin
  select id into session_id from public.lesson_sessions where class_id = (select id from public.classes where code = 'LIFE-MATH-A');

  if (select state from public.lesson_sessions where id = session_id) <> 'started' then
    raise exception 'start class did not enter started state';
  end if;

  begin
    perform public.advance_lesson_session(session_id, 'started', 'published');
    raise exception 'invalid started-to-published transition succeeded';
  exception when check_violation then null;
  end;

  begin
    perform public.advance_lesson_session(session_id, 'started', 'attendance_marked');
    raise exception 'attendance completed without every enrolled student';
  exception when check_violation then null;
  end;
end;
$$;

insert into public.attendance_records (
  organization_id, branch_id, class_id, lesson_session_id,
  organization_membership_id, status, recorded_by
)
select class_row.organization_id, class_row.branch_id, class_row.id, session.id,
       membership.id, 'present', '30000000-0000-0000-0000-000000000003'
from public.classes class_row
join public.lesson_sessions session on session.class_id = class_row.id
join public.organization_memberships membership on membership.user_id = '30000000-0000-0000-0000-000000000005'
where class_row.code = 'LIFE-MATH-A';

select public.advance_lesson_session(
  (select id from public.lesson_sessions where class_id = (select id from public.classes where code = 'LIFE-MATH-A')),
  'started', 'attendance_marked'
);

select set_config('app.lifecycle.organization_id', (select organization_id::text from public.lesson_sessions limit 1), true);
select set_config('app.lifecycle.branch_id', (select branch_id::text from public.lesson_sessions limit 1), true);
select set_config('app.lifecycle.class_id', (select class_id::text from public.lesson_sessions limit 1), true);
select set_config('app.lifecycle.session_id', (select id::text from public.lesson_sessions limit 1), true);

select set_config('request.jwt.claim.sub', '30000000-0000-0000-0000-000000000004', true);

do $$
declare visible_sessions bigint; affected bigint;
begin
  select count(*) into visible_sessions from public.lesson_sessions;
  if visible_sessions <> 0 then raise exception 'west teacher could read main lesson session'; end if;

  update public.lesson_sessions set title = 'forged west update';
  get diagnostics affected = row_count;
  if affected <> 0 then raise exception 'west teacher updated main lesson session'; end if;

  begin
    insert into public.lesson_uploads (
      organization_id, branch_id, class_id, lesson_session_id, kind, storage_path,
      original_name, mime_type, size_bytes, status, uploaded_at, created_by
    ) values (
      current_setting('app.lifecycle.organization_id')::bigint,
      current_setting('app.lifecycle.branch_id')::bigint,
      current_setting('app.lifecycle.class_id')::bigint,
      current_setting('app.lifecycle.session_id')::bigint,
      'transcript', 'forged/path/forged.txt', 'forged.txt', 'text/plain', 10,
      'uploaded', statement_timestamp(), '30000000-0000-0000-0000-000000000004'
    );
    raise exception 'west teacher inserted main upload metadata';
  exception when insufficient_privilege then null;
  end;
end;
$$;

select set_config('request.jwt.claim.sub', '30000000-0000-0000-0000-000000000003', true);

insert into public.lesson_uploads (
  organization_id, branch_id, class_id, lesson_session_id, kind, storage_path,
  original_name, mime_type, size_bytes, status, uploaded_at, created_by
)
select session.organization_id, session.branch_id, session.class_id, session.id, fixture.kind,
       session.organization_id || '/' || session.branch_id || '/' || session.class_id || '/' || session.id || '/' || fixture.filename,
       fixture.filename, fixture.mime_type, 100, 'uploaded', statement_timestamp(),
       '30000000-0000-0000-0000-000000000003'
from public.lesson_sessions session
cross join (values ('transcript', 'transcript.txt', 'text/plain'), ('resource', 'notes.pdf', 'application/pdf')) as fixture(kind, filename, mime_type);

insert into public.lesson_uploads (
  organization_id, branch_id, class_id, lesson_session_id, kind, storage_path,
  original_name, mime_type, size_bytes, status, failure_message, retry_count, created_by
)
select session.organization_id, session.branch_id, session.class_id, session.id, 'resource',
       session.organization_id || '/' || session.branch_id || '/' || session.class_id || '/' || session.id || '/retry.pdf',
       'retry.pdf', 'application/pdf', 100, 'failed', 'Upload failed. Choose the file again and retry.', 0,
       '30000000-0000-0000-0000-000000000003'
from public.lesson_sessions session;

update public.lesson_uploads
set status = 'pending', failure_message = null, retry_count = retry_count + 1
where original_name = 'retry.pdf';

update public.lesson_uploads
set status = 'uploaded', uploaded_at = statement_timestamp()
where original_name = 'retry.pdf';

select public.advance_lesson_session(
  (select id from public.lesson_sessions where class_id = (select id from public.classes where code = 'LIFE-MATH-A')),
  'attendance_marked', 'evidence_uploaded'
);

insert into public.homework_assignments (
  organization_id, branch_id, class_id, lesson_session_id, title, instructions, created_by
)
select session.organization_id, session.branch_id, session.class_id, session.id,
       'Practice set 3', 'Complete questions 1 to 10.', '30000000-0000-0000-0000-000000000003'
from public.lesson_sessions session;

select public.advance_lesson_session(
  (select id from public.lesson_sessions where class_id = (select id from public.classes where code = 'LIFE-MATH-A')),
  'evidence_uploaded', 'homework_assigned'
);
select public.advance_lesson_session(
  (select id from public.lesson_sessions where class_id = (select id from public.classes where code = 'LIFE-MATH-A')),
  'homework_assigned', 'ai_review_ready'
);

do $$
declare session_id bigint;
begin
  select id into session_id from public.lesson_sessions where class_id = (select id from public.classes where code = 'LIFE-MATH-A');
  begin
    perform public.advance_lesson_session(session_id, 'ai_review_ready', 'published');
    raise exception 'publish bypassed teacher review';
  exception when check_violation then null;
  end;
end;
$$;

select public.advance_lesson_session(
  (select id from public.lesson_sessions where class_id = (select id from public.classes where code = 'LIFE-MATH-A')),
  'ai_review_ready', 'teacher_reviewed'
);
select public.advance_lesson_session(
  (select id from public.lesson_sessions where class_id = (select id from public.classes where code = 'LIFE-MATH-A')),
  'teacher_reviewed', 'published'
);

do $$
declare final_state text; review_user uuid; retry_count_value integer;
begin
  select state, teacher_reviewed_by into final_state, review_user
  from public.lesson_sessions
  where class_id = (select id from public.classes where code = 'LIFE-MATH-A');
  select retry_count into retry_count_value from public.lesson_uploads where original_name = 'retry.pdf';
  if final_state <> 'published' then raise exception 'lifecycle did not publish'; end if;
  if review_user <> '30000000-0000-0000-0000-000000000003' then raise exception 'teacher review attribution failed'; end if;
  if retry_count_value <> 1 then raise exception 'upload retry state was not preserved'; end if;
end;
$$;

rollback;
