-- TASK-003 rollback-safe academic structure and branch-isolation proof.
begin;

insert into auth.users (id, email, raw_user_meta_data)
values
  ('20000000-0000-0000-0000-000000000001', 'academic-platform@example.invalid', '{"display_name":"Academic Platform"}'::jsonb),
  ('20000000-0000-0000-0000-000000000002', 'academic-owner@example.invalid', '{"display_name":"Academic Owner"}'::jsonb),
  ('20000000-0000-0000-0000-000000000003', 'academic-manager@example.invalid', '{"display_name":"Main Manager"}'::jsonb),
  ('20000000-0000-0000-0000-000000000004', 'academic-teacher-main@example.invalid', '{"display_name":"Main Teacher"}'::jsonb),
  ('20000000-0000-0000-0000-000000000005', 'academic-teacher-west@example.invalid', '{"display_name":"West Teacher"}'::jsonb),
  ('20000000-0000-0000-0000-000000000006', 'academic-student-main@example.invalid', '{"display_name":"Main Student"}'::jsonb),
  ('20000000-0000-0000-0000-000000000007', 'academic-student-west@example.invalid', '{"display_name":"West Student"}'::jsonb);

insert into private.platform_role_assignments (user_id)
values ('20000000-0000-0000-0000-000000000001');

set local role authenticated;
select set_config('request.jwt.claim.role', 'authenticated', true);
select set_config('request.jwt.claim.sub', '20000000-0000-0000-0000-000000000001', true);

insert into public.organizations (name, slug, region_code, created_by)
values ('Academic Fixture', 'academic-fixture', 'IN', '20000000-0000-0000-0000-000000000001');

insert into public.branches (organization_id, name, code, timezone, created_by)
select organization.id, fixture.name, fixture.code, 'Asia/Kolkata', '20000000-0000-0000-0000-000000000001'
from public.organizations organization
cross join (values ('Main Campus', 'MAIN'), ('West Campus', 'WEST')) as fixture(name, code)
where organization.slug = 'academic-fixture';

insert into public.organization_memberships (organization_id, user_id, status, joined_at, created_by)
select organization.id, fixture.user_id, 'active', statement_timestamp(), '20000000-0000-0000-0000-000000000001'
from public.organizations organization
cross join (
  values
    ('20000000-0000-0000-0000-000000000002'::uuid),
    ('20000000-0000-0000-0000-000000000003'::uuid),
    ('20000000-0000-0000-0000-000000000004'::uuid),
    ('20000000-0000-0000-0000-000000000005'::uuid),
    ('20000000-0000-0000-0000-000000000006'::uuid),
    ('20000000-0000-0000-0000-000000000007'::uuid)
) as fixture(user_id)
where organization.slug = 'academic-fixture';

insert into public.branch_memberships (organization_id, organization_membership_id, branch_id, created_by)
select membership.organization_id, membership.id, branch.id, '20000000-0000-0000-0000-000000000001'
from public.organization_memberships membership
join public.branches branch
  on branch.organization_id = membership.organization_id
 and branch.code = case
   when membership.user_id in (
     '20000000-0000-0000-0000-000000000003',
     '20000000-0000-0000-0000-000000000004',
     '20000000-0000-0000-0000-000000000006'
   ) then 'MAIN'
   else 'WEST'
 end
where membership.user_id <> '20000000-0000-0000-0000-000000000002';

insert into public.role_assignments (organization_id, organization_membership_id, branch_id, role, assigned_by)
select membership.organization_id, membership.id, branch.id, fixture.role, '20000000-0000-0000-0000-000000000001'
from (
  values
    ('20000000-0000-0000-0000-000000000002'::uuid, 'organization_owner', null::text),
    ('20000000-0000-0000-0000-000000000003'::uuid, 'branch_manager', 'MAIN'),
    ('20000000-0000-0000-0000-000000000004'::uuid, 'teacher', 'MAIN'),
    ('20000000-0000-0000-0000-000000000005'::uuid, 'teacher', 'WEST'),
    ('20000000-0000-0000-0000-000000000006'::uuid, 'student', 'MAIN'),
    ('20000000-0000-0000-0000-000000000007'::uuid, 'student', 'WEST')
) as fixture(user_id, role, branch_code)
join public.organization_memberships membership on membership.user_id = fixture.user_id
left join public.branches branch
  on branch.organization_id = membership.organization_id
 and branch.code = fixture.branch_code;

select set_config('request.jwt.claim.sub', '20000000-0000-0000-0000-000000000002', true);

with bundle as (
  select * from public.create_custom_syllabus_bundle(
    (select id from public.organizations where slug = 'academic-fixture'),
    'MATH-10', 'Grade 10 Mathematics', 'Fixture mathematics syllabus', '2026-27',
    'ALG.1', 'Solve linear equations', 'Solve and check one-variable linear equations.'
  )
)
insert into public.subjects (organization_id, syllabus_id, syllabus_version_id, code, name, created_by)
select (select id from public.organizations where slug = 'academic-fixture'), syllabus_id,
       syllabus_version_id, 'MATH', 'Mathematics', '20000000-0000-0000-0000-000000000002'
from bundle;

with bundle as (
  select * from public.create_custom_syllabus_bundle(
    (select id from public.organizations where slug = 'academic-fixture'),
    'SCI-10', 'Grade 10 Science', 'Fixture science syllabus', '2026-27',
    'PHY.1', 'Explain motion', 'Describe displacement, velocity, and acceleration.'
  )
)
insert into public.subjects (organization_id, syllabus_id, syllabus_version_id, code, name, created_by)
select (select id from public.organizations where slug = 'academic-fixture'), syllabus_id,
       syllabus_version_id, 'SCI', 'Science', '20000000-0000-0000-0000-000000000002'
from bundle;

select * from public.create_class_bundle(
  (select id from public.organizations where slug = 'academic-fixture'),
  (select id from public.branches where code = 'MAIN' and organization_id = (select id from public.organizations where slug = 'academic-fixture')),
  (select id from public.subjects where code = 'MATH' and organization_id = (select id from public.organizations where slug = 'academic-fixture')),
  (select objective.id from public.syllabus_objectives objective join public.subjects subject on subject.syllabus_id = objective.syllabus_id and subject.syllabus_version_id = objective.syllabus_version_id where subject.code = 'MATH' and subject.organization_id = (select id from public.organizations where slug = 'academic-fixture') limit 1),
  'MATH-10-A', 'Mathematics 10 A', '2026-27', 1::smallint, '09:00'::time, '10:00'::time,
  'Room 1', '2026-06-01'::date, null::date
);

select * from public.create_class_bundle(
  (select id from public.organizations where slug = 'academic-fixture'),
  (select id from public.branches where code = 'WEST' and organization_id = (select id from public.organizations where slug = 'academic-fixture')),
  (select id from public.subjects where code = 'SCI' and organization_id = (select id from public.organizations where slug = 'academic-fixture')),
  (select objective.id from public.syllabus_objectives objective join public.subjects subject on subject.syllabus_id = objective.syllabus_id and subject.syllabus_version_id = objective.syllabus_version_id where subject.code = 'SCI' and subject.organization_id = (select id from public.organizations where slug = 'academic-fixture') limit 1),
  'SCI-10-W', 'Science 10 West', '2026-27', 2::smallint, '11:00'::time, '12:00'::time,
  'Lab 2', '2026-06-01'::date, null::date
);

do $$
declare
  branch_count bigint;
  subject_count bigint;
  class_count bigint;
  lineage_count bigint;
  timetable_count bigint;
begin
  select count(*) into branch_count from public.branches where organization_id = (select id from public.organizations where slug = 'academic-fixture');
  select count(*) into subject_count from public.subjects where organization_id = (select id from public.organizations where slug = 'academic-fixture');
  select count(*) into class_count from public.classes where organization_id = (select id from public.organizations where slug = 'academic-fixture');
  select count(*) into lineage_count from public.class_objectives where organization_id = (select id from public.organizations where slug = 'academic-fixture');
  select count(*) into timetable_count from public.timetable_entries where organization_id = (select id from public.organizations where slug = 'academic-fixture');
  if branch_count <> 2 or subject_count <> 2 or class_count <> 2 or lineage_count <> 2 or timetable_count <> 2 then
    raise exception 'academic fixture integrity failed';
  end if;

  begin
    perform * from public.create_class_bundle(
      (select id from public.organizations where slug = 'academic-fixture'),
      (select id from public.branches where code = 'MAIN' and organization_id = (select id from public.organizations where slug = 'academic-fixture')),
      (select id from public.subjects where code = 'MATH' and organization_id = (select id from public.organizations where slug = 'academic-fixture')),
      (select objective.id from public.syllabus_objectives objective join public.subjects subject on subject.syllabus_id = objective.syllabus_id and subject.syllabus_version_id = objective.syllabus_version_id where subject.code = 'SCI' and subject.organization_id = (select id from public.organizations where slug = 'academic-fixture') limit 1),
      'BAD-LINEAGE', 'Bad lineage', '2026-27', 3::smallint, '13:00'::time, '14:00'::time,
      '', '2026-06-01'::date, null::date
    );
    raise exception 'mismatched objective unexpectedly created a class';
  exception when foreign_key_violation or check_violation then null;
  end;

  begin
    insert into public.class_teachers (organization_id, branch_id, class_id, organization_membership_id, created_by)
    select class_row.organization_id, class_row.branch_id, class_row.id, membership.id,
           '20000000-0000-0000-0000-000000000002'
    from public.classes class_row
    join public.organization_memberships membership on membership.user_id = '20000000-0000-0000-0000-000000000005'
    where class_row.code = 'MATH-10-A';
    raise exception 'west teacher was assigned to main class';
  exception when foreign_key_violation or check_violation then null;
  end;

  begin
    insert into public.class_enrollments (organization_id, branch_id, class_id, organization_membership_id, created_by)
    select class_row.organization_id, class_row.branch_id, class_row.id, membership.id,
           '20000000-0000-0000-0000-000000000002'
    from public.classes class_row
    join public.organization_memberships membership on membership.user_id = '20000000-0000-0000-0000-000000000007'
    where class_row.code = 'MATH-10-A';
    raise exception 'west student was enrolled in main class';
  exception when foreign_key_violation or check_violation then null;
  end;
end;
$$;

select set_config('request.jwt.claim.sub', '20000000-0000-0000-0000-000000000003', true);

do $$
declare
  visible_classes bigint;
  visible_west bigint;
  affected bigint;
begin
  select count(*) into visible_classes from public.classes;
  select count(*) into visible_west from public.classes class_row join public.branches branch on branch.id = class_row.branch_id where branch.code = 'WEST';
  if visible_classes <> 1 or visible_west <> 0 then raise exception 'branch manager isolation failed'; end if;

  begin
    perform * from public.create_class_bundle(
      (select id from public.organizations where slug = 'academic-fixture'),
      (select id from public.branches where code = 'WEST' and organization_id = (select id from public.organizations where slug = 'academic-fixture')),
      (select id from public.subjects where code = 'MATH' and organization_id = (select id from public.organizations where slug = 'academic-fixture')),
      (select objective.id from public.syllabus_objectives objective join public.subjects subject on subject.syllabus_id = objective.syllabus_id and subject.syllabus_version_id = objective.syllabus_version_id where subject.code = 'MATH' and subject.organization_id = (select id from public.organizations where slug = 'academic-fixture') limit 1),
      'FORGED-WEST', 'Forged west class', '2026-27', 4::smallint, '14:00'::time, '15:00'::time,
      '', '2026-06-01'::date, null::date
    );
    raise exception 'main manager created west class';
  exception when insufficient_privilege then null;
  end;

  insert into public.class_teachers (organization_id, branch_id, class_id, organization_membership_id, created_by)
  select class_row.organization_id, class_row.branch_id, class_row.id, membership.id,
         '20000000-0000-0000-0000-000000000003'
  from public.classes class_row
  join public.organization_memberships membership on membership.user_id = '20000000-0000-0000-0000-000000000005'
  where class_row.code = 'MATH-10-A';
  get diagnostics affected = row_count;
  if affected <> 0 then raise exception 'branch manager could assign invisible west teacher'; end if;
end;
$$;

insert into public.class_teachers (organization_id, branch_id, class_id, organization_membership_id, created_by)
select class_row.organization_id, class_row.branch_id, class_row.id, membership.id,
       '20000000-0000-0000-0000-000000000003'
from public.classes class_row
join public.organization_memberships membership on membership.user_id = '20000000-0000-0000-0000-000000000004'
where class_row.code = 'MATH-10-A';

insert into public.class_enrollments (organization_id, branch_id, class_id, organization_membership_id, created_by)
select class_row.organization_id, class_row.branch_id, class_row.id, membership.id,
       '20000000-0000-0000-0000-000000000003'
from public.classes class_row
join public.organization_memberships membership on membership.user_id = '20000000-0000-0000-0000-000000000006'
where class_row.code = 'MATH-10-A';

select set_config('request.jwt.claim.sub', '20000000-0000-0000-0000-000000000006', true);

do $$
declare visible_classes bigint; visible_west bigint; visible_timetable bigint;
begin
  select count(*) into visible_classes from public.classes;
  select count(*) into visible_west from public.classes class_row join public.branches branch on branch.id = class_row.branch_id where branch.code = 'WEST';
  select count(*) into visible_timetable from public.timetable_entries;
  if visible_classes <> 1 or visible_west <> 0 or visible_timetable <> 1 then
    raise exception 'student isolation failed: classes %, west %, timetable %', visible_classes, visible_west, visible_timetable;
  end if;
end;
$$;

rollback;
